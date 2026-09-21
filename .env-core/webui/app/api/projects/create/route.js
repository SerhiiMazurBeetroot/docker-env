import { NextResponse } from "next/server";
import { streamCreateProject } from "../../../../lib/cli";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function POST(request) {
	let payload = {};
	try {
		payload = await request.json();
	} catch (err) {
		return NextResponse.json({ ok: false, error: "Invalid JSON" }, { status: 400 });
	}

	const result = streamCreateProject(payload.type || "", payload.domain || "", payload.options || {}, request.signal);

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
