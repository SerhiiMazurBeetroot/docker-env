import { NextResponse } from "next/server";
import { recordDiagnostic } from "../../../lib/diagnostics";
import { wipFeatureDenied } from "../../../lib/features";
import { isCheckRunning, readUpdates, runUpdatesCheck, sortUpdateItems, summarizeUpdates } from "../../../lib/updates";

function view() {
	const data = readUpdates();
	if (!data) return null;
	return { ...data, items: sortUpdateItems(data.items), summary: summarizeUpdates(data.items) };
}

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export function GET() {
	const denied = wipFeatureDenied("updates");
	if (denied) return NextResponse.json(denied.body, { status: denied.status });

	return NextResponse.json({ ok: true, running: isCheckRunning(), data: view() });
}

// "Check now": run the check, then return the fresh file.
export async function POST() {
	const denied = wipFeatureDenied("updates");
	if (denied) return NextResponse.json(denied.body, { status: denied.status });

	const result = await runUpdatesCheck();
	const data = view();
	if (result.code !== 0) {
		const log = `${result.stdout}\n${result.stderr}`.trim();
		recordDiagnostic({ source: "webui", action: "updates", message: "Updates check failed", detail: log });
		return NextResponse.json({ ok: false, error: "Updates check failed", log, data }, { status: 502 });
	}
	return NextResponse.json({ ok: true, running: false, data });
}
