"use client";

import { useEffect, useRef } from "react";
import { useConsoleSettings } from "../console/ConsoleSettingsProvider";
import { IconExternal, Spinner } from "../ui/Icons";
import { linkify } from "../../lib/logs";
import LogViewer from "../logs/LogViewer";

/* Console output (CLI stream or container logs) with its controls. Used by the dock and the Activity page. */
export default function ConsolePanel({
	mode = "cli",
	log,
	entries = [],
	title = "Console",
	logLive,
	onClear,
	onStop,
	dozzleUrl = "",
	actions = null,
	className = "",
}) {
	const logRef = useRef(null);
	const isLogs = mode === "logs";
	const { autoScroll, setAutoScroll } = useConsoleSettings();

	useEffect(() => {
		if (!autoScroll || !logRef.current) return;
		logRef.current.scrollTop = logRef.current.scrollHeight;
	}, [log, mode, autoScroll]);

	return (
		<div className={`flex min-h-0 flex-col overflow-hidden rounded-2xl border border-line bg-ink/80 ${className}`}>
			<div className="flex shrink-0 flex-wrap items-center gap-x-3 gap-y-1 border-b border-line px-4 py-2.5">
				<span className={`led ${logLive ? "led-on bg-ok animate-pulsedot" : "bg-muted/50"}`} />
				<span className="min-w-0 truncate font-mono text-[12px] uppercase tracking-[0.12em] text-muted">
					{title}
					{logLive ? " · live" : ""}
				</span>
				<div className="ml-auto flex items-center gap-3 text-xs">
					{dozzleUrl ? (
						<a
							href={dozzleUrl}
							target="_blank"
							rel="noreferrer"
							className="inline-flex items-center gap-1 text-muted hover:text-accent"
							title="Open this container in Dozzle"
						>
							<IconExternal className="h-3 w-3" />
							Dozzle
						</a>
					) : null}
					{logLive && onStop ? (
						<button type="button" className="text-muted hover:text-fg" onClick={onStop}>
							Stop
						</button>
					) : null}
					<button
						type="button"
						className={`inline-flex items-center gap-1.5 hover:text-fg ${autoScroll ? "text-fg" : "text-muted"}`}
						onClick={() => setAutoScroll(!autoScroll)}
						aria-pressed={autoScroll}
						title={autoScroll ? "Autoscroll on. Click to pause." : "Autoscroll off. Click to follow."}
					>
						<span
							aria-hidden
							className={`h-1.5 w-1.5 rounded-full ${autoScroll ? "bg-ok shadow-[0_0_6px_rgb(var(--ok))]" : "bg-muted/50"}`}
						/>
						Autoscroll
					</button>
					<button
						type="button"
						className="text-muted hover:text-fg disabled:opacity-40"
						disabled={isLogs ? entries.length === 0 : !log}
						onClick={onClear}
					>
						Clear
					</button>
					{actions}
				</div>
			</div>
			<div className="flex min-h-0 flex-1 flex-col">
				{isLogs ? (
					entries.length ? (
						<LogViewer entries={entries} follow={autoScroll} className="min-h-0 flex-1 px-3 py-2" />
					) : (
						<p className="m-0 flex items-center gap-2 px-4 py-6 text-sm text-muted">
							<Spinner className="h-4 w-4 text-accent" />
							Waiting for docker logs…
						</p>
					)
				) : log ? (
					<pre
						ref={logRef}
						className="log-output m-0 min-h-0 flex-1 overflow-auto whitespace-pre-wrap p-4 font-mono text-[12px] leading-5 text-chip"
						dangerouslySetInnerHTML={{ __html: linkify(log) }}
					/>
				) : (
					<p className="m-0 px-4 py-6 text-sm text-muted">
						Click a container on a site card to stream its logs. Start, Stop and Rebuild output shows here too.
					</p>
				)}
			</div>
		</div>
	);
}
