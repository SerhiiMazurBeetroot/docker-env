import assert from "node:assert/strict";
import test from "node:test";
import {
	isSafeBulkScope,
	isSafeContainerName,
	isSafeCreateOption,
	isSafeDomain,
	isSafeServiceName,
} from "../lib/cli/shared.js";
import { normalizeProjectDomain } from "../lib/domain.js";
import { redact } from "../lib/diagnostics.js";

// These values reach `bash webui_cli.sh <args>`; anything a shell or a path
// could misread must be rejected.
const HOSTILE = ["", "a b", "a;rm -rf /", "$(id)", "`id`", "../etc", "a/b", "-rf", "a\nb", "a|b", "a&b", "x'y", 'x"y'];

test("isSafeDomain accepts hostnames and rejects shell input", () => {
	for (const ok of ["blog", "dev.blog.local", "a-1.b-2", "A1"]) assert.equal(isSafeDomain(ok), true, ok);
	for (const bad of [...HOSTILE, "-blog", "blog-", ".blog", "a".repeat(254)]) assert.equal(isSafeDomain(bad), false, bad);
});

test("isSafeCreateOption allows version-like values only", () => {
	for (const ok of ["8.4", "6.8.2", "wp_", "yes", "db-name"]) assert.equal(isSafeCreateOption(ok), true, ok);
	for (const bad of [...HOSTILE.filter((v) => v !== "-rf"), "a".repeat(65)]) assert.equal(isSafeCreateOption(bad), false, bad);
});

test("isSafeServiceName and isSafeContainerName reject shell input", () => {
	for (const ok of ["blog-wordpress", "nginx-proxy", "db_1", "app.web"]) {
		assert.equal(isSafeServiceName(ok), true, ok);
		assert.equal(isSafeContainerName(ok), true, ok);
	}
	for (const bad of HOSTILE) {
		assert.equal(isSafeServiceName(bad), false, bad);
		assert.equal(isSafeContainerName(bad), false, bad);
	}
});

test("isSafeBulkScope allows all, running, stopped and type ids", () => {
	for (const ok of ["all", "running", "stopped", "wordpress", "nodejs_api"]) assert.equal(isSafeBulkScope(ok), true, ok);
	for (const bad of [...HOSTILE, "1abc"]) assert.equal(isSafeBulkScope(bad), false, bad);
});

test("normalizeProjectDomain turns a label into a project name", () => {
	assert.equal(normalizeProjectDomain("  My Blog_Site.local "), "my-blog-site");
	assert.equal(normalizeProjectDomain("--a--b--"), "a-b");
	assert.equal(normalizeProjectDomain("$(id);x"), "idx");
	assert.equal(normalizeProjectDomain(""), "");
	assert.equal(normalizeProjectDomain(null), "");
});

test("redact hides tokens and passwords in saved diagnostics", () => {
	const text = "WEBUI_TOKEN=abc123 MYSQL_ROOT_PASSWORD=pw GIT_ASKPASS_TOKEN=ghp_x keep=this";
	const out = redact(text);
	for (const secret of ["abc123", "=pw", "ghp_x"]) assert.equal(out.includes(secret), false, secret);
	assert.match(out, /keep=this/);
	assert.match(out, /WEBUI_TOKEN=/, "the key name stays for context");
});
