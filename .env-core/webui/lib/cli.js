import path from "path";
import fs from "fs";
import { spawn } from "child_process";
import { parseDockerLogLine } from "./logParse";
import { listProjectsFast, sampleProjectStats, urlsForProject, hostsStatusFor, loadHostsText, hostTokenSet, applyHostsExtras } from "./listSnapshot";

const ACTIONS = new Set(["start", "stop", "restart", "rebuild", "delete"]);
const CREATE_TYPES = new Set([
	"wordpress",
	"bedrock",
	"php",
	"nextjs",
	"directus",
	"elasticsearch",
	"laravel",
	"directus_nextjs",
	"wpnextjs",
	"nodejs",
]);
const CREATE_OPTION_KEYS = new Set([
	"PHP_VERSION",
	"WP_VERSION",
	"NODE_VERSION",
	"NEXTJS_VERSION",
	"DIRECTUS_VERSION",
	"LARAVEL_VERSION",
	"ELASTIC_VERSION",
	"DB_NAME",
	"TABLE_PREFIX",
	"EMPTY_CONTENT",
	"MULTISITE",
]);
const BULK_ACTIONS = new Set(["start", "stop"]);
const SYSTEM_IDS = new Set(["nginx", "dozzle"]);
const SYSTEM_ACTIONS = new Set(["start", "stop", "restart"]);
const SERVICE_ACTIONS = new Set(["start", "stop"]);
const SYSTEM_CONTAINERS = new Set(["nginx-proxy", "nginx-dozzle", "nginx-webui", "nginx-mkcert"]);
const ACTION_TIMEOUT_MS = 5 * 60 * 1000;
const locks = new Set();

function envDir() {
	return process.env.ENV_DIR || process.env.DOCKER_ENV_DIR || path.resolve(process.cwd(), "../..");
}

function cliPath() {
	return path.join(envDir(), ".env-core/webui/webui_cli.sh");
}

function isSafeDomain(domain) {
	return /^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$/.test(domain || "");
}

function extractUrls(text) {
	const match = String(text || "").match(/WEBUI_URLS_JSON:(\[.*\])/m);
	if (!match) return [];
	try {
		const parsed = JSON.parse(match[1]);
		return Array.isArray(parsed) ? parsed : [];
	} catch (err) {
		return [];
	}
}

function stripUrlMarker(text) {
	return String(text || "").replace(/^[ \t]*WEBUI_URLS_JSON:.*$/m, "");
}

function extractJson(text) {
	const trimmed = (text || "").trim();
	if (!trimmed) return null;

	try {
		return JSON.parse(trimmed);
	} catch (err) {
		const start = trimmed.indexOf("{");
		const end = trimmed.lastIndexOf("}");
		if (start >= 0 && end > start) {
			try {
				return JSON.parse(trimmed.slice(start, end + 1));
			} catch (inner) {
				return null;
			}
		}
		return null;
	}
}

function spawnCli(args) {
	const cwd = envDir();
	const env = {
		...process.env,
		ENV_DIR: cwd,
		DOCKER_ENV_DIR: cwd,
	};
	const cli = cliPath();

	if (process.platform === "linux") {
		return spawn("stdbuf", ["-oL", "-eL", "bash", cli, ...args], { cwd, env });
	}

	return spawn("bash", [cli, ...args], { cwd, env });
}

function runCli(args, { onChunk, signal, timeoutMs } = {}) {
	return new Promise((resolve) => {
		const child = spawnCli(args);
		let stdout = "";
		let stderr = "";
		let settled = false;
		let urls = [];

		const emit = (text) => {
			if (onChunk && text) onChunk(text);
		};

		const finish = (code, extraErr = "") => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			signal?.removeEventListener("abort", onAbort);
			urls = extractUrls(stdout);
			resolve({
				code: code == null ? 1 : code,
				stdout,
				stderr: extraErr ? `${stderr}\n${extraErr}` : stderr,
				urls,
			});
		};

		const onAbort = () => {
			child.kill("SIGTERM");
			setTimeout(() => child.kill("SIGKILL"), 2000);
		};

		const timer = setTimeout(() => {
			child.kill("SIGKILL");
		}, timeoutMs || ACTION_TIMEOUT_MS);

		if (signal) {
			if (signal.aborted) onAbort();
			else signal.addEventListener("abort", onAbort);
		}

		child.stdout.on("data", (chunk) => {
			const text = chunk.toString();
			stdout += text;
			emit(text);
		});
		child.stderr.on("data", (chunk) => {
			const text = chunk.toString();
			stderr += text;
			emit(text);
		});
		child.on("error", (error) => {
			finish(1, error.message);
		});
		child.on("close", (code) => {
			finish(code);
		});
	});
}

let listChain = Promise.resolve();

function enqueueList() {
	const task = listChain.then(listProjectsOnce, listProjectsOnce);
	listChain = task.then(
		() => undefined,
		() => undefined
	);
	return task;
}

async function listProjectsOnce() {
	try {
		const fast = await listProjectsFast();
		if (fast.body?.ok && Array.isArray(fast.body.projects)) {
			return { status: 200, body: { ok: true, ...fast.body, partial: false } };
		}
	} catch (err) {
		// fall through to CLI list
	}

	const result = await runCli(["list"]);
	const data = extractJson(result.stdout);

	if (data && Array.isArray(data.projects)) {
		return { status: 200, body: { ok: true, ...data, partial: false } };
	}

	return {
		status: 500,
		body: {
			ok: false,
			error: "Could not list projects",
			log: `${result.stdout}\n${result.stderr}`.trim(),
			code: result.code,
		},
	};
}

let snapshotCache = null;
let cacheDirty = true;
let cacheAt = 0;
const CACHE_TTL_MS = 20_000;

function mergeLiteIntoCache(full, lite) {
	const byDomain = new Map((lite.projects || []).map((item) => [item.domain, item]));
	const byId = new Map((lite.system || []).map((item) => [item.id, item]));
	return {
		...full,
		ok: true,
		partial: false,
		projects: (full.projects || []).map((item) => {
			const hit = byDomain.get(item.domain);
			return hit ? { ...item, running: hit.running, status: hit.status } : item;
		}),
		system: (full.system || []).map((item) => {
			const hit = byId.get(item.id);
			return hit ? { ...item, running: hit.running, state: hit.state || item.state } : item;
		}),
	};
}

export function getCachedSnapshot() {
	return snapshotCache;
}

export function snapshotCacheIsStale() {
	if (cacheDirty || !snapshotCache?.ok || snapshotCache.partial) return true;
	return Date.now() - cacheAt > CACHE_TTL_MS;
}

export function rememberSnapshot(body) {
	if (!body?.ok) return;
	if (body.partial && snapshotCache && !snapshotCache.partial) {
		snapshotCache = mergeLiteIntoCache(snapshotCache, body);
		return;
	}
	snapshotCache = body;
	if (!body.partial) {
		cacheDirty = false;
		cacheAt = Date.now();
	}
}

export function markSnapshotDirty() {
	cacheDirty = true;
}

export async function listProjects({ force = false } = {}) {
	if (!force && snapshotCache?.ok && !snapshotCache.partial && !cacheDirty) {
		return { status: 200, body: snapshotCache };
	}

	let result = await enqueueList();
	if (!result.body?.ok) {
		await new Promise((resolve) => setTimeout(resolve, 400));
		result = await enqueueList();
	}
	if (result.body?.ok) rememberSnapshot(result.body);
	return result;
}

function actionGuard(action, domain) {
	if (!ACTIONS.has(action)) {
		return { status: 404, body: { ok: false, error: "Not found" } };
	}
	if (!isSafeDomain(domain)) {
		return { status: 400, body: { ok: false, error: "Invalid domain" } };
	}
	return null;
}

function systemGuard(id, action) {
	if (!SYSTEM_IDS.has(id) || !SYSTEM_ACTIONS.has(action)) {
		return { status: 404, body: { ok: false, error: "Not found" } };
	}
	return null;
}

function isSafeBulkScope(scope) {
	return /^(all|running|stopped|[A-Za-z][A-Za-z0-9_-]{0,32})$/.test(scope || "");
}

function streamLockedCli(args, lockKey, signal, doneMeta) {
	if (locks.has("bulk") || (lockKey === "bulk" && locks.size > 0) || locks.has(lockKey)) {
		return {
			error: {
				status: 409,
				body: { ok: false, error: `An action is already running for ${doneMeta.target}` },
			},
		};
	}

	locks.add(lockKey);

	const encoder = new TextEncoder();
	let closed = false;

	const stream = new ReadableStream({
		start(controller) {
			const send = (payload) => {
				if (closed) return;
				controller.enqueue(encoder.encode(`data: ${JSON.stringify(payload)}\n\n`));
			};

			runCli(args, {
				signal,
				onChunk: (text) => send({ type: "log", text }),
				timeoutMs: doneMeta.timeoutMs,
			})
				.then((result) => {
					const log = stripUrlMarker(`${result.stdout}\n${result.stderr}`).trim();
					send({
						type: "done",
						ok: result.code === 0,
						...doneMeta,
						error: result.code === 0 ? "" : `Failed to ${doneMeta.action} ${doneMeta.target}`,
						log,
					});
					if (doneMeta.domain) {
						const label = doneMeta.service
							? `${doneMeta.action} ${doneMeta.service}`
							: doneMeta.action;
						recordLastAction(doneMeta.domain, label, result.code === 0);
					}
				})
				.catch((error) => {
					send({
						type: "done",
						ok: false,
						...doneMeta,
						error: error.message || `Failed to ${doneMeta.action} ${doneMeta.target}`,
						log: "",
					});
				})
				.finally(() => {
					locks.delete(lockKey);
					markSnapshotDirty();
					if (!closed) {
						closed = true;
						controller.close();
					}
				});
		},
		cancel() {
			closed = true;
			locks.delete(lockKey);
		},
	});

	return { stream };
}

export function streamProjectAction(action, domain, signal) {
	const guard = actionGuard(action, domain);
	if (guard) return { error: guard };

	const args = action === "delete" ? ["delete", domain] : [action, domain];
	return streamLockedCli(args, `domain:${domain}`, signal, {
		domain,
		action,
		target: domain,
		timeoutMs: action === "delete" ? 10 * 60 * 1000 : undefined,
	});
}

function isSafeCreateOption(value) {
	return /^[A-Za-z0-9._-]{1,64}$/.test(value || "");
}

export async function listProjectTypes() {
	const result = await runCli(["types"]);
	const data = extractJson(result.stdout);
	if (data?.ok && Array.isArray(data.types)) {
		return { status: 200, body: data };
	}
	return { status: 500, body: { ok: false, error: "Could not list project types" } };
}

export function streamCreateProject(type, domain, options, signal) {
	if (!CREATE_TYPES.has(type) || !isSafeDomain(domain)) {
		return { error: { status: 400, body: { ok: false, error: "Invalid type or domain" } } };
	}

	const extras = [];
	for (const [key, value] of Object.entries(options || {})) {
		if (!value) continue;
		if (!CREATE_OPTION_KEYS.has(key) || !isSafeCreateOption(String(value))) {
			return { error: { status: 400, body: { ok: false, error: `Invalid option ${key}` } } };
		}
		extras.push(`${key}=${value}`);
	}

	return streamLockedCli(["create", type, domain, ...extras], `domain:${domain}`, signal, {
		domain,
		action: "create",
		target: domain,
		timeoutMs: 20 * 60 * 1000,
	});
}

export function streamBulkAction(action, scope, signal) {
	if (!BULK_ACTIONS.has(action) || !isSafeBulkScope(scope)) {
		return { error: { status: 400, body: { ok: false, error: "Invalid bulk action" } } };
	}

	return streamLockedCli(["bulk", action, scope], "bulk", signal, {
		action,
		scope,
		target: scope === "all" || scope === "running" || scope === "stopped" ? `all ${scope}` : scope,
		timeoutMs: 20 * 60 * 1000,
	});
}

export function streamSystemAction(id, action, signal) {
	const guard = systemGuard(id, action);
	if (guard) return { error: guard };

	return streamLockedCli(["system", id, action], `system:${id}`, signal, {
		id,
		action,
		target: id,
	});
}

function isSafeServiceName(name) {
	return /^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$/.test(name || "");
}

function serviceGuard(domain, action, service) {
	if (!SERVICE_ACTIONS.has(action)) {
		return { status: 404, body: { ok: false, error: "Not found" } };
	}
	if (!isSafeDomain(domain) || !isSafeServiceName(service)) {
		return { status: 400, body: { ok: false, error: "Invalid service" } };
	}
	return null;
}

export function streamServiceAction(domain, action, service, signal) {
	const guard = serviceGuard(domain, action, service);
	if (guard) return { error: guard };

	return streamLockedCli(["service", domain, action, service], `domain:${domain}`, signal, {
		domain,
		action,
		service,
		target: `${domain}/${service}`,
	});
}

export function streamHostsAction(action, domain, signal) {
	if (!new Set(["add", "rem"]).has(action) || !isSafeDomain(domain)) {
		return { error: { status: 400, body: { ok: false, error: "Invalid hosts action" } } };
	}

	const lockKey = `domain:${domain}`;
	if (locks.has("bulk") || locks.has(lockKey)) {
		return {
			error: {
				status: 409,
				body: { ok: false, error: `An action is already running for ${domain}` },
			},
		};
	}

	locks.add(lockKey);
	const encoder = new TextEncoder();
	let closed = false;

	const stream = new ReadableStream({
		start(controller) {
			const send = (payload) => {
				if (closed) return;
				controller.enqueue(encoder.encode(`data: ${JSON.stringify(payload)}\n\n`));
			};

			const abort = () => {
				closed = true;
			};
			if (signal?.aborted) abort();
			else signal?.addEventListener("abort", abort);

			applyHostsExtras(action, domain)
				.then((result) => {
					send({ type: "log", text: `${result.log || ""}\n` });
					send({
						type: "done",
						ok: !!result.ok,
						domain,
						action: action === "add" ? "add hosts extras" : "remove hosts extras",
						target: domain,
						error: result.ok ? "" : result.log || "Hosts update failed",
						log: result.log || "",
					});
					if (result.ok) recordLastAction(domain, action === "add" ? "add hosts extras" : "remove hosts extras", true);
				})
				.catch((error) => {
					send({
						type: "done",
						ok: false,
						domain,
						error: error.message || "Hosts update failed",
						log: "",
					});
				})
				.finally(() => {
					locks.delete(lockKey);
					markSnapshotDirty();
					signal?.removeEventListener("abort", abort);
					if (!closed) {
						closed = true;
						controller.close();
					}
				});
		},
		cancel() {
			closed = true;
			locks.delete(lockKey);
		},
	});

	return { stream };
}

export function isSafeContainerName(name) {
	return /^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$/.test(name || "");
}

function isAllowedLogContainer(name) {
	if (SYSTEM_CONTAINERS.has(name)) return true;
	return /^[A-Za-z0-9][A-Za-z0-9.-]{0,80}-[A-Za-z0-9][A-Za-z0-9_.-]{0,80}$/.test(name);
}

function inspectContainerName(name) {
	return new Promise((resolve) => {
		const child = spawn("docker", ["inspect", "--format", "{{.Name}}", name]);
		let out = "";
		child.stdout.on("data", (chunk) => {
			out += chunk.toString();
		});
		child.on("error", () => resolve(""));
		child.on("close", (code) => {
			resolve(code === 0 ? out.trim().replace(/^\//, "") : "");
		});
	});
}

export function streamContainerLogs(name, signal) {
	if (!isSafeContainerName(name) || !isAllowedLogContainer(name)) {
		return { error: { status: 400, body: { ok: false, error: "Invalid container" } } };
	}

	const encoder = new TextEncoder();
	let closed = false;
	let child = null;
	let pingTimer = null;

	const stream = new ReadableStream({
		async start(controller) {
			const sendRaw = (chunk) => {
				if (closed) return;
				controller.enqueue(encoder.encode(chunk));
			};
			const send = (event, payload) => {
				sendRaw(`event: ${event}\ndata: ${JSON.stringify(payload)}\n\n`);
			};

			const stop = () => {
				clearInterval(pingTimer);
				child?.kill("SIGTERM");
				setTimeout(() => child?.kill("SIGKILL"), 1500);
				if (!closed) {
					closed = true;
					try {
						controller.close();
					} catch (err) {
						// already closed
					}
				}
			};

			const inspected = await inspectContainerName(name);
			if (closed) return;
			if (inspected !== name) {
				send("fail", { error: `Container not found: ${name}` });
				stop();
				return;
			}

			child = spawn("docker", ["logs", "--timestamps", "--tail", "200", "-f", "--", name], {
				env: process.env,
			});

			let buffer = "";
			const onChunk = (chunk) => {
				buffer += chunk.toString();
				const lines = buffer.split("\n");
				buffer = lines.pop() || "";
				for (const line of lines) {
					const entry = parseDockerLogLine(line.replace(/\r$/, ""));
					if (entry) send("entry", entry);
				}
			};

			child.stdout.on("data", onChunk);
			child.stderr.on("data", onChunk);
			child.on("error", (error) => {
				send("fail", { error: error.message || "docker logs failed" });
			});
			child.on("close", (code) => {
				if (buffer) {
					const entry = parseDockerLogLine(buffer.replace(/\r$/, ""));
					if (entry) send("entry", entry);
				}
				send("done", { ok: code === 0 });
				stop();
			});

			pingTimer = setInterval(() => sendRaw(": ping\n\n"), 15000);

			const onAbort = () => {
				signal?.removeEventListener("abort", onAbort);
				stop();
			};

			if (signal) {
				if (signal.aborted) onAbort();
				else signal.addEventListener("abort", onAbort);
			}
		},
		cancel() {
			clearInterval(pingTimer);
			closed = true;
			child?.kill("SIGTERM");
			setTimeout(() => child?.kill("SIGKILL"), 1500);
		},
	});

	return { stream };
}

function instancesDir() {
	return path.join(envDir(), ".env-core/data");
}

function instancesLogPath() {
	return path.join(instancesDir(), "instances.log");
}

function dockerNames(args) {
	return new Promise((resolve) => {
		const child = spawn("docker", args, { env: process.env });
		let out = "";
		const timer = setTimeout(() => {
			child.kill("SIGKILL");
			resolve([]);
		}, 4000);
		child.stdout.on("data", (chunk) => {
			out += chunk.toString();
		});
		child.on("error", () => {
			clearTimeout(timer);
			resolve([]);
		});
		child.on("close", () => {
			clearTimeout(timer);
			resolve(
				out
					.split("\n")
					.map((line) => line.trim())
					.filter(Boolean)
			);
		});
	});
}

function parseInstancesLog(text) {
	const rows = [];
	const lines = String(text || "").split(/\r?\n/);

	for (let index = 0; index < lines.length; index += 1) {
		const cols = lines[index].split("|").map((part) => part.trim());
		const domain = cols[2] || "";
		if (!domain || domain === "DOMAIN_NAME") continue;
		if (index === 0 && cols[0] === "PORT") continue;
		rows.push({
			domain,
			status: cols[1] || "",
			domainFull: cols[3] || "",
			type: cols[6] || "",
		});
	}

	return rows;
}

function projectLooksRunning(names, domain) {
	const prefix = `${domain}-`;
	return names.some((name) => name === domain || name.startsWith(prefix));
}

function liteSystemService(id, name, container, urls, actions, names) {
	const running = names.includes(container);
	return {
		id,
		name,
		container,
		running,
		state: running ? "running" : "missing",
		health: "",
		status: "",
		urls,
		actions,
	};
}

export async function listProjectsLite() {
	let raw = "";
	try {
		raw = fs.readFileSync(instancesLogPath(), "utf8");
	} catch (err) {
		raw = "";
	}

	const names = await dockerNames(["ps", "--format", "{{.Names}}"]);
	const hosts = await loadHostsText();
	const tokens = hostTokenSet(hosts.text);
	const webuiHost =
		process.env.WEBUI_HOST && process.env.WEBUI_HOST !== "0.0.0.0" ? process.env.WEBUI_HOST : "127.0.0.1";
	const webuiUrl = `http://${webuiHost}:${process.env.WEBUI_PORT || "7777"}`;
	const systemActions = ["start", "stop", "restart"];

	const projects = parseInstancesLog(raw).map((row) => {
		const urls = urlsForProject(row.type, row.domainFull);
		const url = row.domainFull ? `https://${row.domainFull}` : "";
		return {
			domain: row.domain,
			status: row.status,
			type: row.type,
			domainFull: row.domainFull,
			running: projectLooksRunning(names, row.domain),
			url,
			urls,
			services: [],
			hosts: hostsStatusFor(row.type, row.domainFull, tokens, hosts.ok),
			partial: true,
		};
	});

	return {
		status: 200,
		body: {
			ok: true,
			partial: true,
			projects,
			system: [
				liteSystemService(
					"nginx",
					"Nginx",
					"nginx-proxy",
					[
						{ key: "HTTP", url: "http://127.0.0.1:8080" },
						{ key: "HTTPS", url: "https://127.0.0.1" },
					],
					systemActions,
					names
				),
				liteSystemService(
					"dozzle",
					"Dozzle",
					"nginx-dozzle",
					[{ key: "UI", url: "http://127.0.0.1:7007" }],
					systemActions,
					names
				),
				liteSystemService(
					"webui",
					"Web UI",
					process.env.WEBUI_CONTAINER || "nginx-webui",
					[{ key: "UI", url: webuiUrl }],
					[],
					names
				),
			],
		},
	};
}

const SECRET_KEY_RE = /(password|passwd|secret|token|apikey|api_key|_key$|private|auth|credential|access_key|secret_key)/i;

function lastActionsPath() {
	return path.join(instancesDir(), "webui-last-actions.json");
}

function readLastActions() {
	try {
		const parsed = JSON.parse(fs.readFileSync(lastActionsPath(), "utf8"));
		return parsed && typeof parsed === "object" ? parsed : {};
	} catch (err) {
		return {};
	}
}

function recordLastAction(domain, action, ok) {
	if (!domain || !action) return;
	const current = readLastActions();
	current[domain] = { action, ok: !!ok, at: new Date().toISOString() };
	try {
		fs.mkdirSync(instancesDir(), { recursive: true });
		fs.writeFileSync(lastActionsPath(), `${JSON.stringify(current, null, 2)}\n`);
	} catch (err) {
		// ignore
	}
}

function dockerCapture(args, timeoutMs = 8000) {
	return new Promise((resolve) => {
		const child = spawn("docker", args, { env: process.env });
		let stdout = "";
		let stderr = "";
		const timer = setTimeout(() => {
			child.kill("SIGKILL");
			resolve({ code: 1, stdout, stderr: stderr || "timeout" });
		}, timeoutMs);
		child.stdout.on("data", (chunk) => {
			stdout += chunk.toString();
		});
		child.stderr.on("data", (chunk) => {
			stderr += chunk.toString();
		});
		child.on("error", (error) => {
			clearTimeout(timer);
			resolve({ code: 1, stdout, stderr: error.message });
		});
		child.on("close", (code) => {
			clearTimeout(timer);
			resolve({ code: code == null ? 1 : code, stdout, stderr });
		});
	});
}

function findComposeDir(root, type) {
	const extra = type === "wordpress" || type === "projects" ? path.join(root, "wp-docker") : null;
	const candidates = [extra, path.join(root, "docker"), root].filter(Boolean);
	for (const dir of candidates) {
		if (fs.existsSync(path.join(dir, "docker-compose.yml"))) return dir;
	}
	return candidates[0] || root;
}

function parseEnvKeys(file) {
	if (!file || !fs.existsSync(file)) return [];
	let text = "";
	try {
		text = fs.readFileSync(file, "utf8");
	} catch (err) {
		return [];
	}
	const keys = [];
	const seen = new Set();
	for (const line of text.split(/\r?\n/)) {
		const trimmed = line.trim();
		if (!trimmed || trimmed.startsWith("#")) continue;
		const eq = trimmed.indexOf("=");
		if (eq < 1) continue;
		const key = trimmed.slice(0, eq).trim();
		if (!key || seen.has(key)) continue;
		seen.add(key);
		const raw = trimmed.slice(eq + 1).trim().replace(/^['"]|['"]$/g, "");
		keys.push({
			key,
			set: raw.length > 0,
			secret: SECRET_KEY_RE.test(key),
		});
	}
	return keys;
}

function collectEnvKeys(composeDir, root) {
	const files = [path.join(composeDir, ".env"), path.join(root, ".env")];
	const merged = [];
	const seen = new Set();
	for (const file of files) {
		for (const item of parseEnvKeys(file)) {
			if (seen.has(item.key)) continue;
			seen.add(item.key);
			merged.push(item);
		}
	}
	return merged;
}

function envKeysFromCompose(config) {
	const keys = [];
	const seen = new Set();
	for (const spec of Object.values(config?.services || {})) {
		const env = spec?.environment;
		const names = [];
		if (Array.isArray(env)) {
			for (const item of env) {
				const name = String(item).split("=")[0].trim();
				if (name) names.push(name);
			}
		} else if (env && typeof env === "object") {
			names.push(...Object.keys(env));
		}
		for (const key of names) {
			if (seen.has(key)) continue;
			seen.add(key);
			keys.push({ key, set: true, secret: SECRET_KEY_RE.test(key) });
		}
	}
	return keys;
}

function mergeEnvKeys(...lists) {
	const merged = [];
	const seen = new Set();
	for (const list of lists) {
		for (const item of list || []) {
			if (!item?.key || seen.has(item.key)) continue;
			seen.add(item.key);
			merged.push(item);
		}
	}
	return merged.sort((a, b) => a.key.localeCompare(b.key));
}

function readComposePreview(file) {
	if (!file || !fs.existsSync(file)) return "";
	try {
		return fs.readFileSync(file, "utf8").split(/\r?\n/).slice(0, 120).join("\n");
	} catch (err) {
		return "";
	}
}

function parseComposeJson(raw) {
	try {
		return JSON.parse(raw);
	} catch (err) {
		return null;
	}
}

function portsFromCompose(config) {
	const ports = [];
	const services = config?.services || {};
	for (const [service, spec] of Object.entries(services)) {
		for (const item of spec?.ports || []) {
			if (typeof item === "string") {
				const match = item.match(/^(\d+):(\d+)/);
				if (match) ports.push({ service, published: match[1], target: match[2], protocol: "tcp" });
				continue;
			}
			if (item && (item.published || item.target)) {
				ports.push({
					service,
					published: String(item.published || ""),
					target: String(item.target || ""),
					protocol: item.protocol || "tcp",
				});
			}
		}
	}
	return ports;
}

function volumesFromCompose(config, composeDir) {
	const volumes = [];
	const named = new Set(Object.keys(config?.volumes || {}));
	const services = config?.services || {};
	for (const [service, spec] of Object.entries(services)) {
		for (const item of spec?.volumes || []) {
			if (typeof item === "string") {
				const [source, target] = item.split(":");
				const isNamed = named.has(source) || !source.startsWith(".") && !source.startsWith("/");
				volumes.push({
					service,
					type: isNamed ? "volume" : "bind",
					source,
					destination: target || "",
				});
				continue;
			}
			if (!item) continue;
			volumes.push({
				service,
				type: item.type || (item.source && String(item.source).startsWith("/") ? "bind" : "volume"),
				source: item.source || "",
				destination: item.target || item.destination || "",
			});
		}
	}
	return volumes.map((item) => {
		if (item.type === "bind" && item.source && !path.isAbsolute(item.source)) {
			return { ...item, source: path.resolve(composeDir, item.source) };
		}
		return item;
	});
}

function formatKb(kb) {
	const n = Number(kb);
	if (!Number.isFinite(n) || n < 0) return "";
	if (n < 1024) return `${Math.round(n)} KB`;
	if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} MB`;
	return `${(n / 1024 / 1024).toFixed(2)} GB`;
}

function dirSizeLabel(dir) {
	return new Promise((resolve) => {
		if (!dir || !fs.existsSync(dir)) {
			resolve("");
			return;
		}
		const child = spawn("du", ["-sk", dir]);
		let out = "";
		const timer = setTimeout(() => {
			child.kill("SIGKILL");
			resolve("");
		}, 3000);
		child.stdout.on("data", (chunk) => {
			out += chunk.toString();
		});
		child.on("error", () => {
			clearTimeout(timer);
			resolve("");
		});
		child.on("close", () => {
			clearTimeout(timer);
			const kb = parseInt(out.trim().split(/\s+/)[0], 10);
			resolve(formatKb(kb));
		});
	});
}

function editorUrl(filePath) {
	if (!filePath) return "";
	return `cursor://file${filePath}`;
}

export async function getProjectDetail(domain) {
	if (!isSafeDomain(domain)) {
		return { status: 400, body: { ok: false, error: "Invalid domain" } };
	}

	let raw = "";
	try {
		raw = fs.readFileSync(instancesLogPath(), "utf8");
	} catch (err) {
		raw = "";
	}

	const row = parseInstancesLog(raw).find((item) => item.domain === domain);
	if (!row) {
		return { status: 404, body: { ok: false, error: "Unknown project" } };
	}

	const root = path.join(envDir(), row.type || "", row.domainFull || domain);
	const composeDir = findComposeDir(root, row.type);
	const composeFile = path.join(composeDir, "docker-compose.yml");
	const composeExists = fs.existsSync(composeFile);
	const envFile = fs.existsSync(path.join(composeDir, ".env"))
		? path.join(composeDir, ".env")
		: fs.existsSync(path.join(root, ".env"))
			? path.join(root, ".env")
			: "";

	let composeConfig = null;
	if (composeExists) {
		const args = ["compose", "--project-directory", composeDir, "-f", composeFile, "config", "--format", "json"];
		let captured = await dockerCapture([...args, "--no-interpolate"], 12000);
		composeConfig = parseComposeJson(captured.stdout);
		if (!composeConfig) {
			captured = await dockerCapture(args, 12000);
			composeConfig = parseComposeJson(captured.stdout);
		}
	}

	const last = readLastActions()[domain] || null;
	const disk = await dirSizeLabel(root);
	const env = mergeEnvKeys(collectEnvKeys(composeDir, root), composeConfig ? envKeysFromCompose(composeConfig) : []);

	return {
		status: 200,
		body: {
			ok: true,
			domain: row.domain,
			domainFull: row.domainFull,
			type: row.type,
			status: row.status,
			paths: {
				root,
				composeDir,
				composeFile: composeExists ? composeFile : "",
				envFile,
			},
			editor: {
				root: editorUrl(root),
				compose: composeExists ? editorUrl(composeFile) : "",
				env: envFile ? editorUrl(envFile) : "",
			},
			composePreview: readComposePreview(composeExists ? composeFile : ""),
			ports: composeConfig ? portsFromCompose(composeConfig) : [],
			volumes: composeConfig ? volumesFromCompose(composeConfig, composeDir) : [],
			env,
			disk: { project: disk || "" },
			lastAction: last,
		},
	};
}

function snapshotEquals(a, b) {
	return JSON.stringify(a) === JSON.stringify(b);
}

export function streamProjectSnapshots(signal) {
	const encoder = new TextEncoder();
	let closed = false;
	let lastBody = null;
	let refreshTimer = null;
	let inFlight = false;
	let queued = false;
	let eventsChild = null;
	let watcher = null;
	let pingTimer = null;
	let statsTimer = null;

	const stream = new ReadableStream({
		start(controller) {
			const sendRaw = (chunk) => {
				if (closed) return;
				controller.enqueue(encoder.encode(chunk));
			};

			const sendSnapshot = (body) => {
				if (closed) return;
				sendRaw(`event: snapshot\ndata: ${JSON.stringify(body)}\n\n`);
			};

			const refresh = async ({ includeLite = false, force = false } = {}) => {
				if (closed) return;
				if (inFlight) {
					queued = true;
					return;
				}
				inFlight = true;
				try {
					if (includeLite && !getCachedSnapshot()) {
						const lite = await listProjectsLite();
						if (!closed && lite.body?.ok) {
							rememberSnapshot(lite.body);
							lastBody = lite.body;
							sendSnapshot(lite.body);
						}
					}
					const result = await listProjects({ force });
					if (result.body?.ok) {
						if (!snapshotEquals(lastBody, result.body)) {
							lastBody = result.body;
							sendSnapshot(result.body);
						}
						sendStats();
					} else if (!lastBody?.ok) {
						sendSnapshot(result.body);
					}
				} catch (error) {
					if (!lastBody?.ok) {
						sendSnapshot({ ok: false, error: error.message || "Could not list projects" });
					}
				} finally {
					inFlight = false;
					if (queued) {
						queued = false;
						refresh({ force: true });
					}
				}
			};

			const scheduleRefresh = () => {
				markSnapshotDirty();
				clearTimeout(refreshTimer);
				refreshTimer = setTimeout(() => refresh({ force: true }), 250);
			};

			const sendStats = async () => {
				if (closed) return;
				try {
					const projects = lastBody?.projects || getCachedSnapshot()?.projects || [];
					const sampled = await sampleProjectStats(projects);
					if (!closed && sampled?.ok) {
						sendRaw(`event: stats\ndata: ${JSON.stringify(sampled)}\n\n`);
					}
				} catch (err) {
					// keep the list usable without stats
				}
			};

			const cached = getCachedSnapshot();
			if (cached?.ok) {
				lastBody = cached;
				sendSnapshot(cached);
				sendStats();
			}
			if (!cached?.ok) {
				refresh({ includeLite: true, force: true });
			} else if (snapshotCacheIsStale()) {
				refresh({ force: true });
			}

			eventsChild = spawn("docker", ["events", "--filter", "type=container", "--format", "{{json .}}"], {
				env: process.env,
			});
			eventsChild.stdout.on("data", scheduleRefresh);
			eventsChild.stderr.on("data", () => {});
			eventsChild.on("error", () => {
				if (!closed) sendRaw(`event: error\ndata: ${JSON.stringify({ error: "docker events unavailable" })}\n\n`);
			});
			eventsChild.on("close", () => {
				if (!closed) scheduleRefresh();
			});

			try {
				const dir = instancesDir();
				if (fs.existsSync(dir)) {
					watcher = fs.watch(dir, (_event, filename) => {
						if (!filename || filename === "instances.log") {
							scheduleRefresh();
						}
					});
				}
			} catch (err) {
				// listing still works from docker events
			}

			pingTimer = setInterval(() => {
				sendRaw(": ping\n\n");
			}, 15000);
			statsTimer = setInterval(sendStats, 10000);

			const onAbort = () => {
				closed = true;
				clearTimeout(refreshTimer);
				clearInterval(pingTimer);
				clearInterval(statsTimer);
				eventsChild?.kill("SIGTERM");
				watcher?.close();
				signal?.removeEventListener("abort", onAbort);
				try {
					controller.close();
				} catch (err) {
					// already closed
				}
			};

			if (signal) {
				if (signal.aborted) onAbort();
				else signal.addEventListener("abort", onAbort);
			}
		},
		cancel() {
			closed = true;
			clearTimeout(refreshTimer);
			clearInterval(pingTimer);
			clearInterval(statsTimer);
			eventsChild?.kill("SIGTERM");
			watcher?.close();
		},
	});

	return { stream };
}
