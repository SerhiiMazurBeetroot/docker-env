import assert from "node:assert/strict";
import test from "node:test";
import { extractJson, extractUrls, stripUrlMarker } from "../lib/cli/run.js";
import { failureLine } from "../lib/cli/shared.js";
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

// A real failed delete: the shell explains why, then compose prints a deprecation warning.
const FAILED_DELETE = [
	"\u001b[0;33mSnapshot database before delete\u001b[0m",
	"",
	"🛑 \u001b[0;101m[ERROR]\u001b[0;31m Timeout waiting for database in test-dir-postgres\u001b[0m",
	"",
	"🛑 \u001b[0;101m[ERROR]\u001b[0;31m Delete cancelled. The database snapshot failed.\u001b[0m",
	'time="2026-11-26T10:36:57Z" level=warning msg="/x/docker/docker-compose.yml: the attribute `version` is obsolete, it will be ignored, please remove it to avoid potential confusion"',
].join("\n");

test("failureLine reports the first shell [ERROR] (the cause), not what follows it", () => {
	assert.equal(failureLine(FAILED_DELETE), "Timeout waiting for database in test-dir-postgres");
});

// A real failed create: the image build fails, then rollback prints more [ERROR] lines and
// compose warnings. The build failure is the cause.
const FAILED_CREATE = [
	"#9 16.23 Error: ERR_PNPM_IGNORED_BUILDS",
	'#9 ERROR: process "/bin/sh -c pnpm install directus-extension-api-viewer" did not complete successfully: exit code: 1',
	"🛑 \u001b[0;101m[ERROR]\u001b[0;31m Create failed. Removing the partial site [directus-test].\u001b[0m",
	"🛑 \u001b[0;101m[ERROR]\u001b[0;31m dev.directus-test.local was not found in your /host-etc-hosts\u001b[0m",
	'time="2026-11-26T11:20:08Z" level=warning msg="the attribute `version` is obsolete"',
	'failed to solve: process "/bin/sh -c pnpm install directus-extension-api-viewer" did not complete successfully: exit code: 1',
].join("\n");

test("failureLine prefers a docker build failure and adds the tool error code", () => {
	assert.equal(
		failureLine(FAILED_CREATE),
		'failed to solve: process "/bin/sh -c pnpm install directus-extension-api-viewer" did not complete successfully: exit code: 1 (ERR_PNPM_IGNORED_BUILDS)',
	);
});

test("failureLine skips docker warnings when there is no [ERROR] line", () => {
	const log = [
		"Error response from daemon: port is already allocated",
		'time="2026-11-26T10:36:57Z" level=warning msg="the attribute `version` is obsolete"',
		"Container blog-db  Started",
	].join("\n");
	assert.equal(failureLine(log), "Error response from daemon: port is already allocated");
});

test("failureLine falls back when the log has nothing useful", () => {
	assert.equal(failureLine('time="2026-11-26T10:36:57Z" level=warning msg="x"', "Delete failed"), "Delete failed");
	assert.equal(failureLine(""), "Command failed");
});
