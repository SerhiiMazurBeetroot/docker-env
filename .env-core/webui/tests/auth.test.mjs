import assert from "node:assert/strict";
import test from "node:test";
import {
	WEBUI_AUTH_COOKIE,
	isAuthConfigured,
	isAuthorizedRequest,
	readExpectedToken,
	tokenFromRequest,
	tokenMatches,
} from "../lib/auth.js";
import { makeEnvDir, withEnv } from "./helpers.mjs";

function request(headers = {}) {
	return new Request("http://localhost/api/projects", { headers });
}

test("tokenMatches compares exactly and in constant time", () => {
	assert.equal(tokenMatches("abc", "abc"), true);
	assert.equal(tokenMatches("abd", "abc"), false);
	assert.equal(tokenMatches("abcd", "abc"), false, "length differs");
	assert.equal(tokenMatches("", "abc"), false);
	assert.equal(tokenMatches("abc", ""), false, "empty expected never matches");
});

test("tokenFromRequest reads the bearer header first, then the cookie", () => {
	assert.equal(tokenFromRequest(request({ authorization: "Bearer  tok-1 " })), "tok-1");
	assert.equal(tokenFromRequest(request({ cookie: `a=1; ${WEBUI_AUTH_COOKIE}=tok%202` })), "tok 2");
	assert.equal(
		tokenFromRequest(request({ authorization: "Bearer head", cookie: `${WEBUI_AUTH_COOKIE}=cookie` })),
		"head",
	);
	assert.equal(tokenFromRequest(request({ authorization: "Basic xyz" })), "");
	assert.equal(tokenFromRequest(request()), "");
});

test("WEBUI_TOKEN from the environment wins over settings.log", (t) => {
	const dir = makeEnvDir(t, { ".env-core/data/settings.log": "WEBUI_TOKEN=from-file\n" });
	withEnv(t, { ENV_DIR: dir, WEBUI_TOKEN: " from-env " });
	assert.equal(readExpectedToken(), "from-env");
});

test("settings.log is the fallback, quotes are stripped", (t) => {
	const dir = makeEnvDir(t, { ".env-core/data/settings.log": "ENV_MODE=development\nWEBUI_TOKEN='quoted'\n" });
	withEnv(t, { ENV_DIR: dir, WEBUI_TOKEN: null });
	assert.equal(readExpectedToken(), "quoted");
	assert.equal(isAuthConfigured(), true);
});

test("auth fails closed when no token is configured", (t) => {
	const dir = makeEnvDir(t);
	withEnv(t, { ENV_DIR: dir, WEBUI_TOKEN: null });
	assert.equal(isAuthConfigured(), false);
	assert.equal(isAuthorizedRequest(request()), false);
	assert.equal(isAuthorizedRequest(request({ authorization: "Bearer anything" })), false);
});

test("a configured token lets only matching requests in", (t) => {
	withEnv(t, { WEBUI_TOKEN: "secret" });
	assert.equal(isAuthorizedRequest(request({ authorization: "Bearer secret" })), true);
	assert.equal(isAuthorizedRequest(request({ cookie: `${WEBUI_AUTH_COOKIE}=secret` })), true);
	assert.equal(isAuthorizedRequest(request({ authorization: "Bearer wrong" })), false);
	assert.equal(isAuthorizedRequest(request()), false);
});
