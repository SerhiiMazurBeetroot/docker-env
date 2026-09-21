"use client";

import { useEffect, useRef } from "react";
import { IconClose, IconExternal, Spinner } from "../ui/Icons";
import { linkify } from "../../lib/logs";
import LogViewer from "../logs/LogViewer";

export default function Console({
	mode = "cli",
	log,
	entries = [],
	title = "Console",
	logOpen,
	logLive,
	onToggle,
	onClear,
	onStop,
	dozzleUrl = "",
}) {
	const logRef = useRef(null);
	const isLogs = mode === "logs";

	useEffect(() => {
		if (logRef.current) {
			logRef.current.scrollTop = logRef.current.scrollHeight;
		}
	}, [log, logOpen, mode]);

	return (
		<>
			{!logOpen ? (
				<button
					type="button"
					onClick={onToggle}
					className="fixed bottom-4 right-4 z-30 inline-flex h-11 items-center gap-2 rounded-xl border border-line bg-panel px-3 text-xs font-semibold text-fg shadow-card md:hidden"
				>
					<span className={`h-1.5 w-1.5 rounded-full ${logLive ? "bg-ok animate-pulsedot" : "bg-muted"}`} />
					Console
				</button>
			) : null}

			<aside
				className={`flex flex-col border-line bg-panel/95 backdrop-blur-xl ${
					logOpen
						? "fixed inset-0 z-50 pb-[env(safe-area-inset-bottom)] md:static md:inset-auto md:z-30 md:h-full md:w-[min(32rem,42vw)] md:border-l md:pb-0"
						: "hidden md:z-30 md:flex md:h-full md:w-11 md:border-l"
				}`}
			>
				<div
					className={`flex shrink-0 items-center gap-2 border-b border-line ${
						logOpen
							? "px-3 py-2.5 pt-[max(0.625rem,env(safe-area-inset-top))]"
							: "h-full flex-col justify-start px-0 py-3"
					}`}
				>
					<button
						type="button"
						onClick={onToggle}
						className={`inline-flex min-w-0 flex-1 items-center gap-2 text-xs font-semibold uppercase tracking-wider text-muted hover:text-fg ${
							logOpen ? "" : "h-full w-full flex-col justify-start"
						}`}
						aria-expanded={logOpen}
					>
						<span className={`h-1.5 w-1.5 shrink-0 rounded-full ${logLive ? "bg-ok animate-pulsedot" : "bg-white/25"}`} />
						{logOpen ? (
							<span className="truncate">
								{title} {logLive ? "live" : ""}
							</span>
						) : (
							<span className="mt-3 [writing-mode:vertical-rl] rotate-180 tracking-[0.2em]">Console</span>
						)}
					</button>
					{logOpen ? (
						<div className="ml-auto flex shrink-0 items-center gap-2">
							{dozzleUrl ? (
								<a
									href={dozzleUrl}
									target="_blank"
									rel="noreferrer"
									className="hidden items-center gap-1 text-xs text-muted hover:text-accent sm:inline-flex"
									title="Open this container in Dozzle"
								>
									<IconExternal className="h-3 w-3" />
									Dozzle
								</a>
							) : null}
							{logLive && onStop ? (
								<button type="button" className="text-xs text-muted hover:text-fg" onClick={onStop}>
									Stop
								</button>
							) : null}
							<button
								type="button"
								className="text-xs text-muted hover:text-fg disabled:opacity-40"
								disabled={isLogs ? entries.length === 0 : !log}
								onClick={onClear}
							>
								Clear
							</button>
							<button
								type="button"
								onClick={onToggle}
								title="Close console"
								aria-label="Close console"
								className="inline-flex h-9 w-9 items-center justify-center rounded-lg border border-line bg-raised text-fg hover:border-accent/40 hover:text-accent md:hidden"
							>
								<IconClose className="h-4 w-4" />
							</button>
						</div>
					) : null}
				</div>

				{logOpen ? (
					<div className="flex min-h-0 flex-1 flex-col">
						{isLogs ? (
							entries.length ? (
								<LogViewer entries={entries} follow className="min-h-0 flex-1 px-3 py-2" />
							) : (
								<p className="m-0 flex items-center gap-2 px-4 py-6 text-sm leading-6 text-muted">
									<Spinner className="h-4 w-4 text-accent" />
									Waiting for docker logs…
								</p>
							)
						) : log ? (
							<pre
								ref={logRef}
								className="log-output min-h-0 flex-1 overflow-auto whitespace-pre-wrap p-4 font-mono text-[12px] leading-5 text-muted"
								dangerouslySetInnerHTML={{ __html: linkify(log) }}
							/>
						) : (
							<p className="m-0 px-4 py-6 text-sm leading-6 text-muted">
								Click a service chip to stream docker logs, or run Start / Rebuild for CLI output.
							</p>
						)}
					</div>
				) : null}
			</aside>
		</>
	);
}
