"use client";

import { useEffect } from "react";
import { createPortal } from "react-dom";
import { IconClose, IconExternal, IconPlay, Spinner } from "../ui/Icons";

/*
 * Shown when a link of a stopped project is clicked: the host would only answer with a proxy error.
 * Rendered in a portal so the card's glow/transition styles can't trap the fixed overlay.
 * "Start" only starts the project; opening the tab after an async start would be popup-blocked.
 */
export default function NotRunningModal({ open, project, url, starting = false, onStart, onClose }) {
	useEffect(() => {
		if (!open) return undefined;
		function onKey(event) {
			if (event.key === "Escape") onClose?.();
		}
		window.addEventListener("keydown", onKey);
		return () => window.removeEventListener("keydown", onKey);
	}, [open, onClose]);

	if (!open || typeof document === "undefined") return null;

	const host = String(url || "").replace(/^https?:\/\//, "");

	function openAnyway() {
		window.open(url, "_blank", "noreferrer");
		onClose?.();
	}

	return createPortal(
		<div className="fixed inset-0 z-50 flex items-center justify-center p-4">
			<button type="button" className="absolute inset-0 bg-ink/60" aria-label="Close" onClick={onClose} />
			<div
				role="dialog"
				aria-modal="true"
				aria-labelledby="not-running-title"
				className="relative z-10 w-full max-w-sm rounded-2xl border border-line bg-panel p-5 shadow-card"
			>
				<div className="mb-3 flex items-start justify-between gap-3">
					<div className="min-w-0">
						<h2 id="not-running-title" className="m-0 text-lg font-extrabold tracking-tight">
							{project} isn&apos;t running
						</h2>
						<p className="mt-1 text-sm text-muted">
							<span className="break-all font-mono text-[12px] text-fg">{host}</span> won&apos;t respond until its
							containers are up.
						</p>
					</div>
					<button
						type="button"
						onClick={onClose}
						className="rounded-lg p-1.5 text-muted hover:bg-raised hover:text-fg"
						aria-label="Close"
					>
						<IconClose />
					</button>
				</div>
				<div className="mt-4 flex flex-wrap items-center gap-2">
					<button
						type="button"
						autoFocus
						disabled={starting}
						onClick={() => {
							onStart?.();
							onClose?.();
						}}
						className="inline-flex h-8 items-center gap-1.5 rounded-lg border border-ok/50 px-3 text-[12px] font-semibold text-ok transition hover:bg-ok/10 disabled:opacity-40"
					>
						{starting ? <Spinner className="h-3.5 w-3.5" /> : <IconPlay />}
						{starting ? "Starting…" : "Start"}
					</button>
					<button
						type="button"
						onClick={openAnyway}
						className="inline-flex h-8 items-center gap-1.5 rounded-lg border border-line px-3 text-[12px] font-semibold text-fg transition hover:border-accent/50 hover:text-accent"
					>
						<IconExternal className="h-3 w-3" />
						Open anyway
					</button>
					<button
						type="button"
						onClick={onClose}
						className="ml-auto h-8 rounded-lg px-3 text-[12px] font-semibold text-muted hover:bg-raised hover:text-fg"
					>
						Cancel
					</button>
				</div>
				<p className="m-0 mt-3 text-[11px] text-muted">The link becomes active once the project reports running.</p>
			</div>
		</div>,
		document.body,
	);
}
