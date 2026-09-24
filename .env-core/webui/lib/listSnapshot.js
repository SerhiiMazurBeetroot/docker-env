import fs from "fs";
import path from "path";
import { spawn } from "child_process";

function envDir() {
	return process.env.ENV_DIR || process.env.DOCKER_ENV_DIR || path.resolve(process.cwd(), "../..");
}

function instancesLogPath() {
	return path.join(envDir(), ".env-core/data/instances.log");
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

function parseJsonLines(text) {
	const trimmed = String(text || "").trim();
	if (!trimmed) return [];
	if (trimmed.startsWith("[")) {
		try {
			const parsed = JSON.parse(trimmed);
			return Array.isArray(parsed) ? parsed : [];
		} catch (err) {
			return [];
		}
	}
	const rows = [];
	for (const line of trimmed.split(/\r?\n/)) {
		try {
			rows.push(JSON.parse(line));
		} catch (err) {
			// skip
		}
	}
	return rows;
}

export function parseInstancesLog(text) {
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

export function findComposeDir(root, type) {
	const extra = type === "wordpress" || type === "projects" ? path.join(root, "wp-docker") : null;
	const candidates = [extra, path.join(root, "docker"), root].filter(Boolean);
	for (const dir of candidates) {
		if (fs.existsSync(path.join(dir, "docker-compose.yml"))) return dir;
	}
	return candidates[0] || root;
}

export function extraHostsForType(type, domainFull) {
	if (!domainFull) return [];
	switch (type) {
		case "wordpress":
		case "projects":
		case "bedrock":
		case "laravel":
			return [
				{ key: "DOMAIN_DB", host: `${domainFull}.phpmyadmin` },
				{ key: "DOMAIN_MAIL", host: `${domainFull}.mail` },
			];
		case "wordpress_nextjs":
			return [
				{ key: "DOMAIN_ADMIN", host: `${domainFull}.wp` },
				{ key: "DOMAIN_DB", host: `${domainFull}.phpmyadmin` },
				{ key: "DOMAIN_MAIL", host: `${domainFull}.mail` },
			];
		case "directus":
			return [{ key: "DOMAIN_DB", host: `${domainFull}.pgadmin` }];
		case "directus_nextjs":
			return [
				{ key: "DOMAIN_ADMIN", host: `${domainFull}.directus` },
				{ key: "DOMAIN_DB", host: `${domainFull}.pgadmin` },
			];
		case "elasticsearch":
			return [
				{ key: "DOMAIN_LOGSTASH", host: `${domainFull}.logstash` },
				{ key: "DOMAIN_KIBANA", host: `${domainFull}.kibana` },
			];
		default:
			return [];
	}
}

export function urlsForProject(type, domainFull) {
	if (!domainFull) return [];
	const urls = [{ key: "DOMAIN_FULL", url: `https://${domainFull}` }];
	if (type === "wordpress" || type === "projects") {
		urls.push({ key: "DOMAIN_ADMIN", url: `https://${domainFull}/wp-admin` });
	} else if (type === "bedrock") {
		urls.push({ key: "DOMAIN_ADMIN", url: `https://${domainFull}/wp/wp-admin` });
	} else if (type === "laravel") {
		urls.push({ key: "DOMAIN_ADMIN", url: `https://${domainFull}/login` });
	}
	for (const extra of extraHostsForType(type, domainFull)) {
		urls.push({ key: extra.key, url: `https://${extra.host}` });
	}
	return urls;
}

let hostsCache = { at: 0, text: "", ok: false };

export function hostsFilePath() {
	if (fs.existsSync("/host-etc-hosts")) return "/host-etc-hosts";
	let inDocker = false;
	try {
		inDocker = fs.existsSync("/.dockerenv");
	} catch (err) {
		inDocker = false;
	}
	if (!inDocker && fs.existsSync("/etc/hosts")) return "/etc/hosts";
	return "";
}

async function webuiImage() {
	const name = process.env.WEBUI_CONTAINER || "nginx-webui";
	const captured = await dockerCapture(["inspect", "-f", "{{.Config.Image}}", name], 3000);
	return captured.stdout.trim() || "busybox:1.36";
}

function dockerStdin(args, input, timeoutMs = 12000) {
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
		try {
			child.stdin.write(input);
			child.stdin.end();
		} catch (err) {
			clearTimeout(timer);
			resolve({ code: 1, stdout, stderr: err.message });
		}
	});
}

export async function loadHostsText(force = false) {
	if (!force && hostsCache.at && Date.now() - hostsCache.at < 8000) {
		return hostsCache;
	}

	const file = hostsFilePath();
	if (file) {
		try {
			const text = fs.readFileSync(file, "utf8");
			hostsCache = { at: Date.now(), text, ok: true };
			return hostsCache;
		} catch (err) {
			// try docker next
		}
	}

	const image = await webuiImage();
	const captured = await dockerCapture(
		["run", "--rm", "--network", "none", "-v", "/etc/hosts:/check-hosts:ro", "--entrypoint", "cat", image, "/check-hosts"],
		10000
	);
	hostsCache = {
		at: Date.now(),
		text: captured.code === 0 ? captured.stdout : "",
		ok: captured.code === 0,
	};
	return hostsCache;
}

export async function writeHostsText(text) {
	const file = hostsFilePath();
	if (file) {
		try {
			fs.writeFileSync(file, text);
			hostsCache = { at: Date.now(), text, ok: true };
			return { ok: true };
		} catch (err) {
			// try docker next
		}
	}

	const image = await webuiImage();
	const captured = await dockerStdin(
		["run", "--rm", "-i", "--network", "none", "-v", "/etc/hosts:/check-hosts", "--entrypoint", "tee", image, "/check-hosts"],
		text
	);
	const ok = captured.code === 0;
	if (ok) hostsCache = { at: Date.now(), text, ok: true };
	return { ok, log: captured.stderr };
}

function rewriteHosts(text, action, site, extras) {
	const extraList = extras.filter(Boolean);
	const lines = String(text || "").split(/\n/);
	const hadTrailing = text.endsWith("\n");
	let found = false;
	const next = lines.map((raw) => {
		const hash = raw.indexOf("#");
		const body = hash >= 0 ? raw.slice(0, hash) : raw;
		const comment = hash >= 0 ? raw.slice(hash) : "";
		if (!body.trim()) return raw;
		const parts = body.trim().split(/\s+/);
		if (parts.length < 2) return raw;
		if (!parts.slice(1).includes(site)) return raw;
		found = true;
		const ip = parts[0];
		let names = parts.slice(1);
		if (action === "rem") names = names.filter((name) => !extraList.includes(name));
		if (!names.includes(site)) names = [site, ...names];
		if (action === "add") {
			for (const extra of extraList) {
				if (!names.includes(extra)) names.push(extra);
			}
		}
		return `${[ip, ...names].join(" ")}${comment ? ` ${comment}` : ""}`;
	});
	if (action === "add" && !found) {
		if (next.length && next[next.length - 1] === "") next.pop();
		next.push(["127.0.0.1", site, ...extraList].join(" "));
	}
	let out = next.join("\n");
	if (hadTrailing && !out.endsWith("\n")) out += "\n";
	return out;
}

export async function applyHostsExtras(action, domain) {
	let raw = "";
	try {
		raw = fs.readFileSync(instancesLogPath(), "utf8");
	} catch (err) {
		raw = "";
	}
	const row = parseInstancesLog(raw).find((item) => item.domain === domain);
	if (!row) return { ok: false, log: `Unknown project ${domain}` };

	const extras = extraHostsForType(row.type, row.domainFull).map((item) => item.host);
	if (!extras.length) {
		return { ok: true, log: `No extra hosts for ${row.type || "this project"}` };
	}

	const loaded = await loadHostsText(true);
	if (!loaded.ok) {
		return { ok: false, log: "Could not read host /etc/hosts. Recreate Web UI or check Docker volume access." };
	}

	const next = rewriteHosts(loaded.text, action, row.domainFull, extras);
	const written = await writeHostsText(next);
	if (!written.ok) {
		return { ok: false, log: written.log || "Could not write host /etc/hosts" };
	}
	const verb = action === "rem" ? "Removed extras from" : "Added extras to";
	return { ok: true, log: `${verb} /etc/hosts for ${row.domainFull}\n${extras.join(" ")}` };
}

export function hostTokenSet(text) {
	const tokens = new Set();
	for (const raw of String(text || "").split(/\r?\n/)) {
		const line = raw.replace(/#.*$/, "").trim();
		if (!line) continue;
		const parts = line.split(/\s+/).slice(1);
		for (const part of parts) {
			if (part) tokens.add(part.toLowerCase());
		}
	}
	return tokens;
}

export function hostsStatusFor(type, domainFull, tokens, readable) {
	const extras = extraHostsForType(type, domainFull);
	const siteHost = String(domainFull || "").split("/")[0].toLowerCase();
	const site = !!siteHost && tokens.has(siteHost);
	const extraRows = extras.map((item) => ({
		key: item.key,
		host: item.host,
		present: tokens.has(item.host.toLowerCase()),
	}));
	const extrasWanted = extraRows.length > 0;
	const extrasComplete = extrasWanted && extraRows.every((item) => item.present);
	const extrasAny = extraRows.some((item) => item.present);
	return {
		readable,
		site,
		extras: extraRows,
		extrasWanted,
		extrasComplete,
		extrasAny,
		action: !readable ? "" : extrasWanted && extrasComplete ? "rem" : "add",
	};
}

function composeServiceNames(file) {
	if (!file || !fs.existsSync(file)) return [];
	let text = "";
	try {
		text = fs.readFileSync(file, "utf8");
	} catch (err) {
		return [];
	}
	const names = [];
	let inServices = false;
	for (const line of text.split(/\r?\n/)) {
		if (/^services:\s*(#.*)?$/.test(line)) {
			inServices = true;
			continue;
		}
		if (inServices && /^[A-Za-z]/.test(line)) break;
		if (!inServices) continue;
		const match = line.match(/^ {2}([A-Za-z0-9._-]+):\s*(#.*)?$/);
		if (match) names.push(match[1]);
	}
	return names;
}

function labelMap(labels) {
	const map = {};
	if (labels && typeof labels === "object" && !Array.isArray(labels)) return labels;
	for (const part of String(labels || "").split(",")) {
		const eq = part.indexOf("=");
		if (eq < 1) continue;
		map[part.slice(0, eq)] = part.slice(eq + 1);
	}
	return map;
}

function containerName(row) {
	return String(row?.Names || row?.Name || "")
		.split(",")[0]
		.replace(/^\//, "")
		.trim();
}

function healthFromStatus(state, status) {
	const text = `${status || ""}`.toLowerCase();
	if (text.includes("(unhealthy)")) return "unhealthy";
	if (text.includes("health: starting") || text.includes("(starting)")) return "starting";
	if (text.includes("(healthy)")) return "healthy";
	return "";
}

function servicesForProject(row, psRows) {
	const domain = row.domain;
	const prefix = `${domain}-`;
	const root = path.join(envDir(), row.type || "", row.domainFull || domain);
	const composeDir = findComposeDir(root, row.type);
	const composeFile = path.join(composeDir, "docker-compose.yml");
	const defined = composeServiceNames(composeFile);
	const hits = psRows.filter((item) => {
		const name = containerName(item);
		return name === domain || name.startsWith(prefix);
	});
	const byService = new Map();
	for (const item of hits) {
		const labels = labelMap(item.Labels);
		const name = containerName(item);
		const service = labels["com.docker.compose.service"] || (name.startsWith(prefix) ? name.slice(prefix.length) : name);
		const state = String(item.State || "").toLowerCase();
		const status = item.Status || "";
		byService.set(service, {
			service,
			name,
			state: state || "missing",
			status,
			health: healthFromStatus(state, status),
			running: state === "running",
		});
	}
	const names = defined.length ? defined : [...byService.keys()];
	return names.map((service) => {
		return (
			byService.get(service) || {
				service,
				name: `${domain}-${service}`,
				state: "missing",
				status: "",
				health: "",
				running: false,
			}
		);
	});
}

function systemFromPs(psRows) {
	const byName = new Map(psRows.map((item) => [containerName(item), item]));
	const webuiHost =
		process.env.WEBUI_HOST && process.env.WEBUI_HOST !== "0.0.0.0" ? process.env.WEBUI_HOST : "127.0.0.1";
	const webuiUrl = `http://${webuiHost}:${process.env.WEBUI_PORT || "7777"}`;
	const systemActions = ["start", "stop", "restart"];

	function one(id, name, container, urls, actions) {
		const hit = byName.get(container);
		const state = String(hit?.State || "").toLowerCase();
		const running = state === "running";
		return {
			id,
			name,
			container,
			running,
			state: hit ? state || "missing" : "missing",
			health: healthFromStatus(state, hit?.Status || ""),
			status: hit?.Status || "",
			urls,
			actions,
		};
	}

	return [
		one(
			"nginx",
			"Nginx",
			"nginx-proxy",
			[
				{ key: "HTTP", url: "http://127.0.0.1:8080" },
				{ key: "HTTPS", url: "https://127.0.0.1" },
			],
			systemActions
		),
		one("dozzle", "Dozzle", "nginx-dozzle", [{ key: "UI", url: "http://127.0.0.1:7007" }], systemActions),
		one("webui", "Web UI", process.env.WEBUI_CONTAINER || "nginx-webui", [{ key: "UI", url: webuiUrl }], []),
	];
}

export async function listProjectsFast() {
	let raw = "";
	try {
		raw = fs.readFileSync(instancesLogPath(), "utf8");
	} catch (err) {
		raw = "";
	}

	const [captured, hosts] = await Promise.all([
		dockerCapture(["ps", "-a", "--format", "{{json .}}"], 8000),
		loadHostsText(),
	]);
	const psRows = parseJsonLines(captured.stdout);
	const tokens = hostTokenSet(hosts.text);
	const rows = parseInstancesLog(raw);

	const projects = rows.map((row) => {
		const services = servicesForProject(row, psRows);
		const urls = urlsForProject(row.type, row.domainFull);
		const url = row.domainFull ? `https://${row.domainFull}` : "";
		return {
			domain: row.domain,
			status: row.status,
			type: row.type,
			domainFull: row.domainFull,
			running: services.some((item) => item.running) || (!services.length && psRows.some((item) => {
				const name = containerName(item);
				return (name === row.domain || name.startsWith(`${row.domain}-`)) && String(item.State || "").toLowerCase() === "running";
			})),
			url,
			urls,
			services,
			hosts: hostsStatusFor(row.type, row.domainFull, tokens, hosts.ok),
			partial: false,
		};
	});

	return {
		status: 200,
		body: {
			ok: true,
			partial: false,
			projects,
			system: systemFromPs(psRows),
		},
	};
}

function parseSize(text) {
	const match = String(text || "").trim().match(/^([\d.]+)\s*([KMGT]i?B)/i);
	if (!match) return 0;
	const amount = Number(match[1]);
	if (!Number.isFinite(amount)) return 0;
	const unit = match[2].toUpperCase();
	const factor = unit.startsWith("K") ? 1024 : unit.startsWith("M") ? 1024 ** 2 : unit.startsWith("G") ? 1024 ** 3 : unit.startsWith("T") ? 1024 ** 4 : 1;
	return amount * factor;
}

function formatBytes(bytes) {
	if (!bytes) return "0 B";
	if (bytes < 1024) return `${Math.round(bytes)} B`;
	if (bytes < 1024 ** 2) return `${(bytes / 1024).toFixed(0)} KB`;
	if (bytes < 1024 ** 3) return `${(bytes / 1024 ** 2).toFixed(1)} MB`;
	return `${(bytes / 1024 ** 3).toFixed(2)} GB`;
}

export async function sampleProjectStats(projects) {
	const running = (projects || []).filter((item) => item.running);
	if (!running.length) return { ok: true, stats: {} };

	const captured = await dockerCapture(["stats", "--no-stream", "--format", "{{json .}}"], 5000);
	const rows = parseJsonLines(captured.stdout);
	const stats = {};

	for (const project of running) {
		const prefix = `${project.domain}-`;
		let cpu = 0;
		let mem = 0;
		let limit = 0;
		const services = [];
		for (const row of rows) {
			const name = containerName(row);
			if (name !== project.domain && !name.startsWith(prefix)) continue;
			const cpuPerc = parseFloat(String(row.CPUPerc || row.CPU || "0").replace("%", "")) || 0;
			const usage = String(row.MemUsage || "");
			const [used, max] = usage.split("/").map((part) => part.trim());
			cpu += cpuPerc;
			mem += parseSize(used);
			limit += parseSize(max);
			services.push({
				name,
				cpu: cpuPerc,
				mem: parseSize(used),
			});
		}
		if (!services.length) continue;
		const memPerc = limit > 0 ? (mem / limit) * 100 : 0;
		stats[project.domain] = {
			cpu: `${cpu.toFixed(cpu >= 10 ? 0 : 1)}%`,
			cpuValue: cpu,
			mem: formatBytes(mem),
			memValue: mem,
			memPerc: memPerc ? `${memPerc.toFixed(0)}%` : "",
			high: mem >= 1.2 * 1024 ** 3 || memPerc >= 25 || cpu >= 80,
		};
	}

	return { ok: true, stats };
}
