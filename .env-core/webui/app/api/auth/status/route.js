import { NextResponse } from "next/server";
import { isAuthConfigured, isAuthorizedRequest } from "../../../../lib/auth";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function GET(request) {
	const authRequired = isAuthConfigured();
	return NextResponse.json({
		ok: true,
		authRequired,
		authenticated: !authRequired || isAuthorizedRequest(request),
	});
}
