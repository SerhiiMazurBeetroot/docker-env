import { NextResponse } from "next/server";
import { isAuthConfigured, isAuthorizedRequest, notConfiguredJson, unauthorizedJson } from "./lib/auth.js";

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
	if (pathname === "/docs" || pathname.startsWith("/docs/")) {
		return true;
	}
	if (pathname.startsWith("/_next/") || pathname === "/favicon.ico" || pathname === "/icon.svg") {
		return true;
	}
	return false;
}

// Token checks live in lib/auth.js so the proxy and the auth routes agree.
// With no token configured every protected path is refused (fail closed).
export function proxy(request) {
	const { pathname } = request.nextUrl;
	if (isPublicPath(pathname)) {
		return NextResponse.next();
	}

	if (isAuthorizedRequest(request)) {
		return NextResponse.next();
	}

	if (pathname.startsWith("/api/")) {
		return isAuthConfigured() ? unauthorizedJson() : notConfiguredJson();
	}

	const login = new URL("/login", request.url);
	login.searchParams.set("from", pathname);
	return NextResponse.redirect(login);
}

export const config = {
	matcher: ["/((?!_next/static|_next/image).*)"],
};
