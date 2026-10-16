"use client";

import { useEffect, useState } from "react";

export default function DiagnosticsCard() {
	const [count, setCount] = useState(null);
	const [note, setNote] = useState("");
	const [busy, setBusy] = useState(false);
	const [error, setError] = useState("");

	useEffect(() => {
		let cancelled = false;
		fetch("/api/diagnostics")
			.then((response) => response.json())
			.then((body) => {
				if (!cancelled && body?.ok) setCount(body.count);
			})
			.catch(() => {
				if (!cancelled) setCount(0);
			});
		return () => {
			cancelled = true;
		};
	}, []);

	async function download() {
		setBusy(true);
		setError("");
		try {
			const response = await fetch("/api/diagnostics/report", {
				method: "POST",
				headers: { "Content-Type": "application/json" },
				body: JSON.stringify({ note }),
			});
			if (!response.ok) {
				setError("Could not build the bug report");
				return;
			}
			const blob = await response.blob();
			const stamp = new Date().toISOString().replace(/[:.]/g, "-");
			const url = URL.createObjectURL(blob);
			const link = document.createElement("a");
			link.href = url;
			link.download = `docker-env-bug-report-${stamp}.json`;
			link.click();
			URL.revokeObjectURL(url);
		} catch (err) {
			setError(err.message || "Could not build the bug report");
		} finally {
			setBusy(false);
		}
	}

	const saved =
		count == null ? "Checking saved errors…" : count === 0 ? "No errors saved in the last 24 hours." : `${count} error${count === 1 ? "" : "s"} saved in the last 24 hours.`;

	return (
		<section className="mt-8 overflow-hidden rounded-2xl border border-line bg-panel/90">
			<div className="flex items-center gap-2 border-b border-line px-4 py-3 text-[11px] font-semibold uppercase tracking-wider text-muted">
				<BugIcon />
				Diagnostics
			</div>
			<div className="space-y-4 px-4 py-4">
				<div>
					<p className="m-0 text-sm font-semibold text-fg">Diagnostic log</p>
					<p className="mt-1 text-xs leading-5 text-muted">
						Failed actions and errors are saved. Successful start, stop, and list calls are not.
					</p>
				</div>
				<p className="m-0 text-sm text-muted">A bug report includes diagnostic data from the last 24 hours only.</p>
				<p className="m-0 text-sm text-fg">{saved}</p>
				<label className="block text-xs text-muted">
					Note (optional)
					<textarea
						value={note}
						onChange={(event) => setNote(event.target.value)}
						maxLength={2000}
						rows={3}
						placeholder="What were you doing when it failed?"
						className="mt-1 w-full resize-y rounded-xl border border-line bg-ink/40 px-3 py-2 text-sm text-fg outline-none focus:border-accent/50"
					/>
				</label>
				{error ? <p className="m-0 text-sm text-danger">{error}</p> : null}
				<button
					type="button"
					onClick={download}
					disabled={busy}
					className="inline-flex items-center gap-2 rounded-lg bg-accent px-3 py-2 text-sm font-semibold text-white disabled:opacity-60"
				>
					<DownloadIcon />
					{busy ? "Preparing…" : "Download bug report"}
				</button>
			</div>
		</section>
	);
}

function BugIcon() {
	return (
		<svg viewBox="0 0 24 24" className="h-3.5 w-3.5" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden>
			<path d="M9 9V8a3 3 0 0 1 6 0v1" />
			<path d="M8 9h8a6 6 0 0 1 1 3v3a5 5 0 0 1-10 0v-3a6 6 0 0 1 1-3" />
			<path d="M3 13h4M17 13h4M12 20v-6" />
		</svg>
	);
}

function DownloadIcon() {
	return (
		<svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden>
			<path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2" />
			<path d="m7 11 5 5 5-5M12 4v12" />
		</svg>
	);
}
