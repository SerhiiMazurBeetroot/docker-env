import { NextResponse } from "next/server";
import { AUTH_NOT_CONFIGURED_ERROR, readExpectedToken, tokenMatches, WEBUI_AUTH_COOKIE } from "../../../../lib/auth";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function POST(request) {
	const expected = readExpectedToken();
	if (!expected) {
		return NextResponse.json({ ok: false, error: AUTH_NOT_CONFIGURED_ERROR }, { status: 503 });
	}

	let body = {};
	try {
		body = await request.json();
	} catch (err) {
		return NextResponse.json({ ok: false, error: "Invalid JSON" }, { status: 400 });
	}

	const token = String(body.token || "").trim();
	if (!tokenMatches(token, expected)) {
		return NextResponse.json({ ok: false, error: "Invalid token" }, { status: 401 });
	}

	const response = NextResponse.json({ ok: true });
	response.cookies.set(WEBUI_AUTH_COOKIE, token, {
		httpOnly: true,
		sameSite: "lax",
		path: "/",
		maxAge: 60 * 60 * 24 * 30,
	});

	return response;
}
