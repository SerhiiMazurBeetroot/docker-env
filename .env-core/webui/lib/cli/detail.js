import fs from "fs";
import path from "path";
import { spawn } from "child_process";
import { composeRelForType, loadProjectCatalog } from "../catalog.js";
import { readSiteNotices } from "../diagnostics.js";
import { findComposeDir, readInstanceSites } from "../listSnapshot";
import { envDir, isSafeDomain } from "./shared.js";

const SECRET_KEY_RE = /(password|passwd|secret|token|apikey|api_key|_key$|private|auth|credential|access_key|secret_key)/i;

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

	const row = readInstanceSites().find((item) => item.domain === domain);
	if (!row) {
		return { status: 404, body: { ok: false, error: "Unknown project" } };
	}

	const root = path.join(/*turbopackIgnore: true*/ envDir(), row.type || "", row.domainFull || domain);
	const catalog = await loadProjectCatalog().catch(() => null);
	const composeDir = findComposeDir(root, row.type, composeRelForType(catalog, row.type));
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

	const last = readSiteNotices()[domain] || null;
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
			ports: composeConfig ? portsFromCompose(composeConfig) : [],
			volumes: composeConfig ? volumesFromCompose(composeConfig, composeDir) : [],
			env,
			disk: { project: disk || "" },
			lastAction: last,
		},
	};
}
