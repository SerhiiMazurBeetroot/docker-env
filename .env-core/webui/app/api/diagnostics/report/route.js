import { buildBugReport } from "../../../../lib/diagnostics";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function POST(request) {
	let note = "";
	try {
		const body = await request.json();
		note = String(body?.note || "");
	} catch {
		note = "";
	}

	const report = buildBugReport(note);
	const stamp = report.generatedAt.replace(/[:.]/g, "-");
	return new Response(JSON.stringify(report, null, 2), {
		headers: {
			"Content-Type": "application/json; charset=utf-8",
			"Content-Disposition": `attachment; filename="docker-env-bug-report-${stamp}.json"`,
			"Cache-Control": "no-store",
		},
	});
}
