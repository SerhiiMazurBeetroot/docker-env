"use client";

import Link from "next/link";
import { IconChevron } from "../ui/Icons";
import ConsolePanel from "./ConsolePanel";

function lastLine(log) {
	const lines = String(log || "").trim().split("\n");
	return lines[lines.length - 1] || "";
}

/* Thin bar pinned to the bottom of Sites and System. It expands into the console. */
export default function ConsoleDock({ open, onToggle, consoleProps }) {
	const { logLive, title, log, mode, entries = [] } = consoleProps;
	const preview = mode === "logs" ? entries[entries.length - 1]?.message || "" : lastLine(log).replace(/<[^>]*>/g, "");
	const hasOutput = mode === "logs" ? entries.length > 0 || logLive : !!log;

	if (!hasOutput && !open) return null;

	return (
		<div className="sticky bottom-0 z-30 mt-auto border-t border-line bg-ink/90 px-4 pb-[max(0.75rem,env(safe-area-inset-bottom))] pt-3 backdrop-blur-xl sm:px-8">
			{open ? (
				<ConsolePanel
					{...consoleProps}
					className="h-[40vh] min-h-[16rem]"
					actions={
						<button type="button" onClick={onToggle} className="text-muted hover:text-fg" aria-label="Collapse console">
							<IconChevron className="h-3.5 w-3.5" />
						</button>
					}
				/>
			) : (
				<div className="flex items-center gap-3 text-sm">
					<span className={`led ${logLive ? "led-on bg-ok animate-pulsedot" : "bg-muted/50"}`} />
					<button type="button" onClick={onToggle} className="flex min-w-0 flex-1 items-center gap-3 text-left">
						<span className="shrink-0 font-mono text-[12px] uppercase tracking-[0.12em] text-muted">{title}</span>
						<span className="truncate font-mono text-[12px] text-chip">{preview}</span>
					</button>
					<Link href="/?view=activity" className="shrink-0 text-[12px] font-semibold text-accent hover:underline">
						Activity
					</Link>
					<button type="button" onClick={onToggle} className="shrink-0 text-muted hover:text-fg" aria-label="Expand console">
						<IconChevron className="h-3.5 w-3.5 rotate-180" />
					</button>
				</div>
			)}
		</div>
	);
}
