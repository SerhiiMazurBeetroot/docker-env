import fs from "fs";
import path from "path";
import crypto from "crypto";

export const WEBUI_AUTH_COOKIE = "docker_env_webui_token";

export function envRoot() {
	return process.env.ENV_DIR || process.env.DOCKER_ENV_DIR || path.resolve(process.cwd(), "../..");
}

export function settingsFilePath() {
	return path.join(envRoot(), ".env-core/data/settings.log");
}

export function readExpectedToken() {
	const fromEnv = String(process.env.WEBUI_TOKEN || "").trim();
	if (fromEnv) {
		return fromEnv;
	}

	try {
		const text = fs.readFileSync(settingsFilePath(), "utf8");
		const line = text
			.split(/\r?\n/)
			.find((row) => row.startsWith("WEBUI_TOKEN="));
		if (!line) {
			return "";
		}
		let value = line.slice("WEBUI_TOKEN=".length).trim();
		if ((value.startsWith("'") && value.endsWith("'")) || (value.startsWith('"') && value.endsWith('"'))) {
			value = value.slice(1, -1);
		}
		return value;
	} catch (err) {
		return "";
	}
}

export function isAuthConfigured() {
	return readExpectedToken().length > 0;
}

export function tokenMatches(got, expected) {
	if (!got || !expected) {
		return false;
	}

	try {
		const a = Buffer.from(String(got));
		const b = Buffer.from(String(expected));
		if (a.length !== b.length) {
			return false;
		}
		return crypto.timingSafeEqual(a, b);
	} catch (err) {
		return false;
	}
}

export function tokenFromRequest(request) {
	const header = request.headers.get("authorization") || "";
	if (header.toLowerCase().startsWith("bearer ")) {
		return header.slice(7).trim();
	}

	const cookieHeader = request.headers.get("cookie") || "";
	for (const part of cookieHeader.split(";")) {
		const trimmed = part.trim();
		if (trimmed.startsWith(`${WEBUI_AUTH_COOKIE}=`)) {
			return decodeURIComponent(trimmed.slice(WEBUI_AUTH_COOKIE.length + 1));
		}
	}

	return "";
}

export function isAuthorizedRequest(request) {
	const expected = readExpectedToken();
	if (!expected) {
		return true;
	}
	return tokenMatches(tokenFromRequest(request), expected);
}

export function unauthorizedJson() {
	return Response.json({ ok: false, error: "Unauthorized" }, { status: 401 });
}
