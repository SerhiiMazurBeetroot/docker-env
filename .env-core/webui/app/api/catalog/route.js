import { NextResponse } from "next/server";
import { listProjectTypes } from "../../../lib/cli";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function GET() {
	const result = await listProjectTypes();
	return NextResponse.json(result.body, { status: result.status });
}
