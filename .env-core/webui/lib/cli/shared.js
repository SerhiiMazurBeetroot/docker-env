import path from "path";
import { writeSiteNotice } from "../diagnostics.js";

export const ACTIONS = new Set(["start", "stop", "restart", "rebuild", "delete"]);
export const CREATE_OPTION_KEYS = new Set([
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
export const BULK_ACTIONS = new Set(["start", "stop"]);
export const SYSTEM_IDS = new Set(["nginx", "dozzle"]);
export const SYSTEM_ACTIONS = new Set(["start", "stop", "restart"]);
export const SERVICE_ACTIONS = new Set(["start", "stop"]);
export const SYSTEM_CONTAINERS = new Set(["nginx-proxy", "nginx-dozzle", "nginx-webui", "nginx-mkcert"]);
export const ACTION_TIMEOUT_MS = 5 * 60 * 1000;

export const locks = new Set();

export function envDir() {
	return process.env.ENV_DIR || process.env.DOCKER_ENV_DIR || path.resolve(process.cwd(), "../..");
}

export function instancesDir() {
	return path.join(envDir(), ".env-core/data");
}

export function isSafeDomain(domain) {
	return /^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$/.test(domain || "");
}

export function isSafeCreateOption(value) {
	return /^[A-Za-z0-9._-]{1,64}$/.test(value || "");
}

export function isSafeBulkScope(scope) {
	return /^(all|running|stopped|[A-Za-z][A-Za-z0-9_-]{0,32})$/.test(scope || "");
}

export function isSafeServiceName(name) {
	return /^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$/.test(name || "");
}

export function isSafeContainerName(name) {
	return /^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$/.test(name || "");
}

function isComposeNoise(line) {
	return (
		/^#\d+\b/.test(line) ||
		/^(Container|Volume|Network|Image)\s/.test(line) ||
		/\b(Creating|Created|Starting|Started|Recreate|Recreated|Built|CACHED)\b/.test(line) ||
		/^(exporting|writing image|naming to|transferring|resolving provenance|DONE )\b/.test(line) ||
		/platform \(linux\//.test(line) ||
		/Compose now can delegate build/.test(line) ||
		/COMPOSE_BAKE/.test(line)
	);
}

export function failureLine(log, fallback) {
	const lines = String(log || "")
		.replace(/\u001b\[[0-9;]*m/g, "")
		.split("\n")
		.map((line) => line.trim())
		.filter(Boolean);
	for (let i = lines.length - 1; i >= 0; i -= 1) {
		const cleaned = lines[i].replace(/^🛑\s*/, "").replace(/^\[ERROR\]\s*/, "").trim();
		if (!cleaned || isComposeNoise(cleaned)) continue;
		return cleaned.slice(0, 500);
	}
	return String(fallback || "Command failed").slice(0, 500);
}

export function recordLastAction(domain, action, ok, message = "") {
	if (!domain) return;
	writeSiteNotice(domain, { action, ok, message });
}
