import { NextResponse } from "next/server";
import { isAuthConfigured, isAuthorizedRequest } from "../../../../lib/auth";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function GET(request) {
	return NextResponse.json({
		ok: true,
		authRequired: true,
		configured: isAuthConfigured(),
		authenticated: isAuthorizedRequest(request),
	});
}
