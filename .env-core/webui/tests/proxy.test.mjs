import assert from "node:assert/strict";
import test from "node:test";
import { NextRequest } from "next/server.js";
import { proxy } from "../proxy.js";
import { makeEnvDir, withEnv } from "./helpers.mjs";

function call(pathname, headers = {}) {
	return proxy(new NextRequest(`http://localhost${pathname}`, { headers }));
}

// NextResponse.next() carries this header; redirects and JSON errors do not.
function passed(response) {
	return response.headers.get("x-middleware-next") === "1";
}

test("without a token, API calls get 503 and pages go to /login", (t) => {
	withEnv(t, { ENV_DIR: makeEnvDir(t), WEBUI_TOKEN: null });

	const api = call("/api/projects");
	assert.equal(api.status, 503);

	const page = call("/settings");
	assert.equal(page.status, 307);
	assert.equal(new URL(page.headers.get("location")).pathname, "/login");
	assert.equal(new URL(page.headers.get("location")).searchParams.get("from"), "/settings");
});

test("public paths stay open without a token", (t) => {
	withEnv(t, { ENV_DIR: makeEnvDir(t), WEBUI_TOKEN: null });
	for (const pathname of ["/login", "/api/health", "/api/auth/login", "/docs", "/docs/web-ui", "/icon.svg"]) {
		assert.ok(passed(call(pathname)), pathname);
	}
});

test("with a token, a wrong or missing token gets 401", (t) => {
	withEnv(t, { WEBUI_TOKEN: "secret" });
	assert.equal(call("/api/projects").status, 401);
	assert.equal(call("/api/projects", { authorization: "Bearer nope" }).status, 401);
});

test("the right token passes for API and pages", (t) => {
	withEnv(t, { WEBUI_TOKEN: "secret" });
	assert.ok(passed(call("/api/projects", { authorization: "Bearer secret" })));
	assert.ok(passed(call("/", { cookie: "docker_env_webui_token=secret" })));
});
