import fs from "fs";
import os from "os";
import path from "path";
import { isDevelopmentMode } from "./docs.js";
import { wipFeatureMap } from "./features.js";

const WINDOW_MS = 24 * 60 * 60 * 1000;
const MAX_EVENTS = 400;
const MAX_DETAIL = 8000;
const DEDUPE_MS = 10 * 60 * 1000;

const SECRET = /(WEBUI_TOKEN|NGROK_AUTH|MYSQL_PWD|MYSQL_ROOT_PASSWORD|PASSWORD|TOKEN|SECRET|GIT_ASKPASS_TOKEN)=([^\s'"]+)/gi;

const recentKeys = new Map();

function envDir() {
	return process.env.ENV_DIR || process.env.DOCKER_ENV_DIR || path.resolve(process.cwd(), "../..");
}

function logFile() {
	return path.join(envDir(), ".env-core", "data", "diagnostics.jsonl");
}

export function redact(text) {
	return String(text || "")
		.replace(SECRET, "$1=[redacted]")
		.replace(/Bearer\s+\S+/gi, "Bearer [redacted]")
		.slice(0, MAX_DETAIL);
}

function readEvents() {
	const file = logFile();
	if (!fs.existsSync(file)) {
		return [];
	}
	const events = [];
	for (const line of fs.readFileSync(file, "utf8").split("\n")) {
		if (!line.trim()) continue;
		try {
			const row = JSON.parse(line);
			if (row && row.ts && row.message) events.push(row);
		} catch {
			// skip a torn line
		}
	}
	return events;
}

function withinWindow(events) {
	const cutoff = Date.now() - WINDOW_MS;
	return events.filter((event) => {
		const ts = Date.parse(event.ts);
		return Number.isFinite(ts) && ts >= cutoff;
	});
}

function writeEvents(events) {
	const file = logFile();
	fs.mkdirSync(path.dirname(file), { recursive: true });
	const body = events.length ? `${events.map((event) => JSON.stringify(event)).join("\n")}\n` : "";
	fs.writeFileSync(file, body, { mode: 0o600 });
	try {
		fs.chmodSync(file, 0o600);
	} catch {
		// best effort
	}
}

export function recordDiagnostic(entry) {
	try {
		const message = redact(entry?.message || "Error").slice(0, 500);
		if (!message.trim()) return false;

		const source = String(entry.source || "webui").slice(0, 40);
		const action = String(entry.action || "").slice(0, 40);
		const target = String(entry.target || "").slice(0, 160);
		const key = `${action}|${target}|${message}`;
		const now = Date.now();
		if (now - (recentKeys.get(key) || 0) < DEDUPE_MS) return false;

		const wrote = withFileLock(`${logFile()}.lock`, () => {
			const events = withinWindow(readEvents());
			const prev = events[events.length - 1];
			if (
				prev &&
				prev.message === message &&
				prev.target === target &&
				now - Date.parse(prev.ts) < DEDUPE_MS
			) {
				return false;
			}
			events.push({
				ts: new Date(now).toISOString(),
				level: "error",
				source,
				action,
				target,
				message,
				detail: redact(entry.detail || ""),
			});
			writeEvents(events.slice(-MAX_EVENTS));
			return true;
		});
		if (wrote) recentKeys.set(key, now);
		return wrote === true;
	} catch {
		return false;
	}
}

export function recentDiagnostics() {
	try {
		const events = withFileLock(`${logFile()}.lock`, () => {
			const rows = withinWindow(readEvents()).slice(-MAX_EVENTS);
			writeEvents(rows);
			return rows;
		});
		return Array.isArray(events) ? events : [];
	} catch {
		return [];
	}
}

export function buildBugReport(note) {
	const events = recentDiagnostics();
	return {
		generatedAt: new Date().toISOString(),
		windowHours: 24,
		product: "docker-env",
		host: {
			platform: os.platform(),
			release: os.release(),
			node: process.version,
		},
		note: redact(note || "").slice(0, 2000),
		count: events.length,
		events,
	};
}

const DOC_BY_TYPE = {
	wordpress: "projects/wordpress",
	bedrock: "projects/bedrock",
	php: "projects/php",
	nextjs: "projects/nextjs",
	directus: "projects/directus",
	elasticsearch: "projects/elasticsearch",
	laravel: "projects/laravel",
	directus_nextjs: "projects/directus-nextjs",
	wordpress_nextjs: "projects/wordpress-nextjs",
	nodejs_api: "projects/nodejs-api",
};

const WIP_TYPES = new Set(["laravel", "directus_nextjs", "wordpress_nextjs", "nodejs", "nodejs_api"]);

export function guideForType(type, development) {
	const slug = DOC_BY_TYPE[type] || "";
	if (!slug) return "";
	if (WIP_TYPES.has(type) && !development) return "";
	return `/docs/${slug}`;
}

function noticesPath() {
	return path.join(envDir(), ".env-core", "data", "webui-last-actions.json");
}

function withFileLock(lockPath, fn) {
	for (let attempt = 0; attempt < 40; attempt += 1) {
		try {
			fs.mkdirSync(lockPath);
		} catch (err) {
			if (err && err.code === "EEXIST") {
				try {
					const age = Date.now() - fs.statSync(lockPath).mtimeMs;
					if (age > 5000) fs.rmdirSync(lockPath);
				} catch {
					// the holder still owns it
				}
				const until = Date.now() + 25;
				while (Date.now() < until) {
					// wait for the other writer
				}
				continue;
			}
			return false;
		}
		try {
			return fn();
		} finally {
			try {
				fs.rmdirSync(lockPath);
			} catch {
				// already released
			}
		}
	}
	return false;
}

export function readSiteNotices() {
	try {
		const parsed = JSON.parse(fs.readFileSync(noticesPath(), "utf8"));
		return parsed && typeof parsed === "object" ? parsed : {};
	} catch {
		return {};
	}
}

export function writeSiteNotice(domain, { action = "", ok = false, message = "" } = {}) {
	if (!domain) return false;
	const file = noticesPath();
	const lock = `${file}.lock`;
	return withFileLock(lock, () => {
		const current = readSiteNotices();
		current[domain] = {
			action: String(action || "").slice(0, 80),
			ok: !!ok,
			message: ok ? "" : redact(message).slice(0, 500),
			at: new Date().toISOString(),
		};
		fs.mkdirSync(path.dirname(file), { recursive: true });
		fs.writeFileSync(file, `${JSON.stringify(current, null, 2)}\n`, { mode: 0o600 });
		return true;
	});
}

function tokenConfigured() {
	try {
		const text = fs.readFileSync(path.join(envDir(), ".env-core", "data", "settings.log"), "utf8");
		const line = text.split(/\r?\n/).find((row) => row.startsWith("WEBUI_TOKEN="));
		if (!line) return false;
		let value = line.slice("WEBUI_TOKEN=".length).trim();
		if ((value.startsWith("'") && value.endsWith("'")) || (value.startsWith('"') && value.endsWith('"'))) {
			value = value.slice(1, -1);
		}
		return value.length > 0;
	} catch {
		return false;
	}
}

export function buildSetup(body) {
	const projects = Array.isArray(body?.projects) ? body.projects : [];
	const system = Array.isArray(body?.system) ? body.system : [];
	const nginx = system.find((item) => item.id === "nginx" || item.container === "nginx-proxy");
	const caFile = path.join(envDir(), ".env-core", "system", "nginx", "certs-root", "rootCA.pem");
	const certificateOk = fs.existsSync(caFile);
	const tokenOk = tokenConfigured();
	const checked = projects.filter((project) => project.hosts && project.domainFull && project.status !== "archive");
	const unreadable = checked.some((project) => project.hosts.readable === false);
	const missing = checked.filter((project) => !project.hosts.site);
	const missingSites = missing.map((project) => ({
		domain: project.domain,
		host: project.domainFull,
	}));

	let hostsOk = true;
	let hostsHint = "Site names are in the hosts file";
	if (!checked.length) {
		hostsHint = "No sites need a hosts entry yet";
	} else if (unreadable) {
		hostsOk = false;
		hostsHint = "Hosts file is not readable from the Web UI";
	} else if (missingSites.length === 1) {
		hostsOk = false;
		hostsHint = `${missingSites[0].host} is not in the hosts file`;
	} else if (missingSites.length) {
		hostsOk = false;
		hostsHint = `${missingSites.length} site hosts are missing`;
	}

	return {
		items: [
			{
				id: "nginx",
				label: "Nginx",
				ok: !!(nginx && nginx.running),
				hint: nginx && nginx.running ? "Proxy is running" : "Start Nginx from System",
			},
			{
				id: "certificate",
				label: "Local CA",
				ok: certificateOk,
				hint: certificateOk ? "rootCA.pem is present" : "Run Nginx setup to create the local CA",
			},
			{
				id: "hosts",
				label: "Hosts",
				ok: hostsOk,
				hint: hostsHint,
				sites: hostsOk || unreadable ? [] : missingSites,
			},
			{
				id: "token",
				label: "Web UI token",
				ok: tokenOk,
				hint: tokenOk ? "WEBUI_TOKEN is set" : "Start the Web UI once so a token is saved",
			},
		],
	};
}

export function decorateList(body) {
	if (!body?.ok) return body;
	const notices = readSiteNotices();
	const development = isDevelopmentMode();
	return {
		...body,
		projects: (body.projects || []).map((project) => ({
			...project,
			guide: guideForType(project.type, development),
			notice: notices[project.domain] || null,
		})),
		setup: buildSetup(body),
		features: wipFeatureMap(),
	};
}
