import { streamProjectSnapshots } from "../../../../lib/cli";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function GET(request) {
	const { stream } = streamProjectSnapshots(request.signal);

	return new Response(stream, {
		headers: {
			"Content-Type": "text/event-stream; charset=utf-8",
			"Cache-Control": "no-cache, no-transform",
			Connection: "keep-alive",
			"X-Accel-Buffering": "no",
		},
	});
}
