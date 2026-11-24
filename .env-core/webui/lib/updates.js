import fs from "fs";
import path from "path";
import { runCli } from "./cli/run.js";
import { envDir } from "./cli/shared.js";

// Developer updates check. sh/system/updates/updates_check.sh writes
// data/updates.json once a day (catalog_refresh loop) or on "Check now".
// This module only reads that file and starts a forced check.

const CHECK_TIMEOUT_MS = 3 * 60 * 1000;
const STATUS_ORDER = ["eol", "rebuild", "recreate", "unpinned", "major", "update", "eol-soon", "stale", "unknown", "ok"];
// Same set as the page: "stale" and "unknown" are information, not a to-do.
const ACTIONABLE = new Set(["update", "major", "recreate", "rebuild", "eol-soon", "eol", "unpinned"]);

let running = null;

export function updatesFilePath() {
	return path.join(envDir(), ".env-core/data/updates.json");
}

export function readUpdates() {
	try {
		const data = JSON.parse(fs.readFileSync(updatesFilePath(), "utf8"));
		if (!data || !Array.isArray(data.items)) return null;
		return data;
	} catch {
		return null;
	}
}

// Rows that need attention first, then by name, so the page stays stable.
export function sortUpdateItems(items = []) {
	const rank = (status) => {
		const index = STATUS_ORDER.indexOf(status);
		return index === -1 ? STATUS_ORDER.length : index;
	};
	return [...items].sort((a, b) => rank(a.status) - rank(b.status) || String(a.name).localeCompare(String(b.name)));
}

export function summarizeUpdates(items = []) {
	const summary = { total: items.length, attention: 0, ok: 0 };
	for (const item of items) {
		if (item.status === "ok") summary.ok += 1;
		else if (ACTIONABLE.has(item.status)) summary.attention += 1;
	}
	return summary;
}

export function isCheckRunning() {
	return running != null;
}

// One check at a time; a second "Check now" joins the one in flight.
export function runUpdatesCheck() {
	if (!running) {
		running = runCli(["updates"], { timeoutMs: CHECK_TIMEOUT_MS }).finally(() => {
			running = null;
		});
	}
	return running;
}
