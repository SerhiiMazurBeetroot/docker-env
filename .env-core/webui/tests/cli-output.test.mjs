import assert from "node:assert/strict";
import test from "node:test";
import { extractJson, extractUrls, stripUrlMarker } from "../lib/cli/run.js";
import { versionChoiceError, versionsForOption } from "../lib/versionChoices.js";

test("extractJson finds the JSON in noisy CLI output", () => {
	assert.deepEqual(extractJson('{"ok":true}'), { ok: true });
	assert.deepEqual(extractJson('\u001b[32mINFO\u001b[0m loading\n{"projects":[]}\ndone'), { projects: [] });
	assert.equal(extractJson("no json here"), null);
	assert.equal(extractJson(""), null);
	assert.equal(extractJson("{broken"), null);
});

test("extractUrls reads the WEBUI_URLS_JSON marker", () => {
	const out = 'Containers Started\nWEBUI_URLS_JSON:[{"key":"DOMAIN_FULL","url":"https://blog.local"}]\nbye';
	assert.deepEqual(extractUrls(out), [{ key: "DOMAIN_FULL", url: "https://blog.local" }]);
	assert.deepEqual(extractUrls("WEBUI_URLS_JSON:[not json]"), []);
	assert.deepEqual(extractUrls('WEBUI_URLS_JSON:{"a":1}'), []);
	assert.deepEqual(extractUrls(undefined), []);
	assert.equal(stripUrlMarker(out).includes("WEBUI_URLS_JSON"), false);
	assert.match(stripUrlMarker(out), /Containers Started/);
});

const catalog = {
	php: ["8.5", "8.4", "8.3"],
	wordpress: ["7.1.3", "6.8.2"],
	wordpressPhp: { "7.1.3": ["8.5", "8.4"], "6.8.2": ["8.4", "8.3"] },
	node: ["24", "22"],
};

test("versionsForOption limits PHP to the chosen WordPress", () => {
	assert.deepEqual(versionsForOption(catalog, "PHP_VERSION"), ["8.5", "8.4", "8.3"]);
	assert.deepEqual(versionsForOption(catalog, "PHP_VERSION", { WP_VERSION: "6.8.2" }), ["8.4", "8.3"]);
	assert.deepEqual(versionsForOption(catalog, "NODE_VERSION"), ["24", "22"]);
	assert.deepEqual(versionsForOption(catalog, "NOT_A_KEY"), []);
	assert.deepEqual(versionsForOption(null, "PHP_VERSION"), []);
});

test("versionChoiceError rejects unpublished versions", () => {
	assert.equal(versionChoiceError({ PHP_VERSION: "8.4", WP_VERSION: "7.1.3" }, catalog), null);
	assert.equal(versionChoiceError({ PHP_VERSION: "" }, catalog), null, "empty means the default");
	assert.match(String(versionChoiceError({ PHP_VERSION: "5.6" }, catalog)), /PHP/);
	assert.match(String(versionChoiceError({ NODE_VERSION: "16" }, catalog)), /Node/);
});
