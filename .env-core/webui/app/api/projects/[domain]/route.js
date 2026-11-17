import { NextResponse } from "next/server";
import { getProjectDetail } from "../../../../lib/cli";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function GET(_request, props) {
	const params = await props.params;
	const domain = decodeURIComponent(params.domain || "");
	const result = await getProjectDetail(domain);
	return NextResponse.json(result.body, { status: result.status });
}
