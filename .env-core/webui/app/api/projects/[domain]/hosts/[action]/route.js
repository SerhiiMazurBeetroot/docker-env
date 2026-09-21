import { NextResponse } from "next/server";
import { streamHostsAction } from "../../../../../../lib/cli";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function POST(request, { params }) {
	const domain = decodeURIComponent(params.domain || "");
	const action = params.action || "";
	const result = streamHostsAction(action, domain, request.signal);

	if (result.error) {
		return NextResponse.json(result.error.body, { status: result.error.status });
	}

	return new Response(result.stream, {
		headers: {
			"Content-Type": "text/event-stream; charset=utf-8",
			"Cache-Control": "no-cache, no-transform",
			Connection: "keep-alive",
			"X-Accel-Buffering": "no",
		},
	});
}
