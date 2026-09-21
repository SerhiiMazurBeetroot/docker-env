import { serviceKind } from "../../lib/projects";
import { IconExternal, IconPlay, IconStop, Spinner } from "./Icons";

const DOTS = {
	running: "bg-ok animate-pulsedot",
	starting: "bg-accent animate-pulsedot",
	restarting: "bg-warn animate-pulsedot",
	unhealthy: "bg-danger",
	paused: "bg-warn",
	stopped: "bg-muted",
	missing: "bg-muted/70",
};

export default function ServiceChip({
	service,
	name,
	domain,
	running,
	state,
	health,
	status,
	active = false,
	busy = "",
	waiting = false,
	dozzleUrl = "",
	onLogs,
	onStart,
	onStop,
}) {
	const raw = name || service || "";
	const prefix = domain ? `${domain}-` : "";
	const label = prefix && raw.startsWith(prefix) ? raw.slice(prefix.length) : raw;
	const kind = serviceKind({ running, state, health, status });
	const missing = kind === "missing";
	const isBusy = !!busy || waiting;
	const canLogs = typeof onLogs === "function" && !missing;
	const canStart = typeof onStart === "function" && !running && !isBusy;
	const canStop = typeof onStop === "function" && running && !isBusy;
	const title = [label, kind !== "running" ? kind : "", status].filter(Boolean).join(" · ");

	return (
		<span
			className={`inline-flex max-w-full items-center gap-0.5 rounded-lg border pl-2 pr-0.5 py-0.5 ${
				active ? "border-accent bg-accent/10" : "border-line bg-raised"
			} ${kind === "unhealthy" ? "border-danger/40" : ""} ${kind === "restarting" ? "border-warn/40" : ""}`}
		>
			{canLogs ? (
				<button
					type="button"
					title={`Logs: ${title}`}
					onClick={onLogs}
					className="inline-flex min-w-0 items-center gap-1.5 hover:text-accent"
				>
					<span className={`h-1.5 w-1.5 shrink-0 rounded-full ${DOTS[kind] || DOTS.stopped}`} />
					<span className="truncate font-mono text-[11px] text-chip">{label}</span>
					{kind === "unhealthy" || kind === "restarting" || kind === "starting" ? (
						<span className="hidden text-[9px] font-semibold uppercase tracking-wider text-muted sm:inline">
							{kind}
						</span>
					) : null}
				</button>
			) : (
				<span title={title} className="inline-flex min-w-0 items-center gap-1.5">
					<span className={`h-1.5 w-1.5 shrink-0 rounded-full ${DOTS[kind] || DOTS.stopped}`} />
					<span className="truncate font-mono text-[11px] text-chip">{label}</span>
				</span>
			)}
			{isBusy ? (
				<Spinner className="mx-1 h-3 w-3 text-accent" />
			) : (
				<span className="ml-0.5 inline-flex">
					{dozzleUrl ? (
						<a
							href={dozzleUrl}
							target="_blank"
							rel="noreferrer"
							title="Open in Dozzle"
							className="rounded p-0.5 text-muted hover:bg-accent/15 hover:text-accent"
						>
							<IconExternal className="h-3 w-3" />
						</a>
					) : null}
					<button
						type="button"
						title={`compose start ${service}`}
						disabled={!canStart}
						onClick={onStart}
						className="rounded p-0.5 text-ok hover:bg-ok/15 disabled:pointer-events-none disabled:text-white/20"
					>
						<IconPlay className="h-3 w-3" />
					</button>
					<button
						type="button"
						title={`compose stop ${service}`}
						disabled={!canStop}
						onClick={onStop}
						className="rounded p-0.5 text-danger hover:bg-danger/15 disabled:pointer-events-none disabled:text-white/20"
					>
						<IconStop className="h-3 w-3" />
					</button>
				</span>
			)}
		</span>
	);
}
