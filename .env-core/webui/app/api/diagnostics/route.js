import { NextResponse } from "next/server";
import { recentDiagnostics, recordDiagnostic } from "../../../lib/diagnostics";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export function GET() {
	const events = recentDiagnostics();
	const latest = events.length ? events[events.length - 1].ts : "";
	return NextResponse.json({ ok: true, count: events.length, latest });
}

export async function POST(request) {
	let body = {};
	try {
		body = await request.json();
	} catch {
		return NextResponse.json({ ok: false, error: "Invalid JSON" }, { status: 400 });
	}

	const message = String(body.message || "").trim();
	if (!message || message.length > 500) {
		return NextResponse.json({ ok: false, error: "Message is required" }, { status: 400 });
	}

	recordDiagnostic({
		source: body.source || "browser",
		action: body.action || "",
		target: body.target || "",
		message,
		detail: body.detail || "",
	});

	return NextResponse.json({ ok: true });
}
