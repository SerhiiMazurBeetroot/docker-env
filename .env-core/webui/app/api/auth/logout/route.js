import { NextResponse } from "next/server";
import { WEBUI_AUTH_COOKIE } from "../../../../lib/auth";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function POST() {
	const response = NextResponse.json({ ok: true });
	response.cookies.set(WEBUI_AUTH_COOKIE, "", {
		httpOnly: true,
		sameSite: "lax",
		path: "/",
		maxAge: 0,
	});
	return response;
}
