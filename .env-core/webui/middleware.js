import { NextResponse } from "next/server";

const COOKIE_NAME = "docker_env_webui_token";

function expectedToken() {
	return (process.env.WEBUI_TOKEN || "").trim();
}

function tokenFromRequest(request) {
	const header = request.headers.get("authorization") || "";
	if (header.toLowerCase().startsWith("bearer ")) {
		return header.slice(7).trim();
	}
	return request.cookies.get(COOKIE_NAME)?.value || "";
}

function tokenMatches(got, expected) {
	if (!got || !expected || got.length !== expected.length) {
		return false;
	}
	let diff = 0;
	for (let i = 0; i < got.length; i += 1) {
		diff |= got.charCodeAt(i) ^ expected.charCodeAt(i);
	}
	return diff === 0;
}

function isPublicPath(pathname) {
	if (pathname === "/login") {
		return true;
	}
	if (pathname === "/api/health") {
		return true;
	}
	if (pathname.startsWith("/api/auth/")) {
		return true;
	}
	if (pathname.startsWith("/_next/") || pathname === "/favicon.ico" || pathname === "/icon.svg") {
		return true;
	}
	return false;
}

export function middleware(request) {
	const expected = expectedToken();
	if (!expected || isPublicPath(request.nextUrl.pathname)) {
		return NextResponse.next();
	}

	if (tokenMatches(tokenFromRequest(request), expected)) {
		return NextResponse.next();
	}

	if (request.nextUrl.pathname.startsWith("/api/")) {
		return NextResponse.json({ ok: false, error: "Unauthorized" }, { status: 401 });
	}

	const login = new URL("/login", request.url);
	login.searchParams.set("from", request.nextUrl.pathname);
	return NextResponse.redirect(login);
}

export const config = {
	matcher: ["/((?!_next/static|_next/image).*)"],
};
