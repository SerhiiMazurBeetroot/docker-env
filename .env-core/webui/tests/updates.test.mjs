import assert from "node:assert/strict";
import test from "node:test";
import { readUpdates, sortUpdateItems, summarizeUpdates } from "../lib/updates.js";
import { makeEnvDir, withEnv } from "./helpers.mjs";

const items = [
	{ id: "a", name: "react", status: "ok" },
	{ id: "b", name: "mkcert", status: "stale" },
	{ id: "c", name: "next", status: "update" },
	{ id: "d", name: "node", status: "rebuild" },
	{ id: "e", name: "tailwind", status: "major" },
	{ id: "f", name: "zz", status: "unknown" },
	{ id: "g", name: "eol-thing", status: "eol" },
	{ id: "h", name: "autoprefixer", status: "update" },
];

test("sortUpdateItems puts work first, then by name", () => {
	assert.deepEqual(
		sortUpdateItems(items).map((item) => item.name),
		["eol-thing", "node", "tailwind", "autoprefixer", "next", "mkcert", "zz", "react"],
	);
	assert.equal(items[0].name, "react", "input is not mutated");
});

test("summarizeUpdates counts only actionable rows as attention", () => {
	assert.deepEqual(summarizeUpdates(items), { total: 8, attention: 5, ok: 1 });
	assert.deepEqual(summarizeUpdates([]), { total: 0, attention: 0, ok: 0 });
});

test("readUpdates returns null for a missing or broken file", (t) => {
	const dir = makeEnvDir(t);
	withEnv(t, { ENV_DIR: dir });
	assert.equal(readUpdates(), null);

	const broken = makeEnvDir(t, { ".env-core/data/updates.json": "{not json" });
	withEnv(t, { ENV_DIR: broken });
	assert.equal(readUpdates(), null);

	const noItems = makeEnvDir(t, { ".env-core/data/updates.json": '{"checked":"x"}' });
	withEnv(t, { ENV_DIR: noItems });
	assert.equal(readUpdates(), null);
});

test("readUpdates returns the file written by updates_check.sh", (t) => {
	const data = { checked: "2026-11-24T00:00:00Z", docker: true, errors: [], items: [items[0]] };
	withEnv(t, { ENV_DIR: makeEnvDir(t, { ".env-core/data/updates.json": JSON.stringify(data) }) });
	assert.deepEqual(readUpdates(), data);
});
