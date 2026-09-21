import { Spinner } from "./Icons";

const TONES = {
	waiting: "bg-accent/12 text-accent",
	building: "bg-accent/12 text-accent",
	starting: "bg-accent/12 text-accent",
	running: "bg-ok/12 text-ok",
	restarting: "bg-warn/12 text-warn",
	unhealthy: "bg-danger/12 text-danger",
	paused: "bg-warn/12 text-warn",
	stopped: "bg-danger/12 text-danger",
	missing: "bg-fg/10 text-muted",
};

const DOTS = {
	running: "bg-ok animate-pulsedot",
	restarting: "bg-warn animate-pulsedot",
	unhealthy: "bg-danger",
	paused: "bg-warn",
	stopped: "bg-danger",
	missing: "bg-muted",
	starting: "bg-accent animate-pulsedot",
	building: "bg-accent animate-pulsedot",
};

export default function StatusBadge({
	running,
	compact = false,
	waiting = false,
	label = "",
	kind = "",
}) {
	const resolved = waiting ? "waiting" : kind || (running ? "running" : "stopped");
	const text = waiting ? label || "waiting" : label || resolved;
	const tone = TONES[resolved] || TONES.stopped;
	const showSpinner = waiting || resolved === "starting" || resolved === "building" || resolved === "restarting";

	return (
		<span
			className={`inline-flex items-center gap-1.5 rounded-full font-semibold ${
				compact ? "px-2 py-0.5 text-[11px]" : "px-2.5 py-1 text-xs"
			} ${tone}`}
		>
			{showSpinner ? (
				<Spinner className={compact ? "h-3 w-3" : "h-3.5 w-3.5"} />
			) : (
				<span className={`h-1.5 w-1.5 rounded-full ${DOTS[resolved] || DOTS.stopped}`} />
			)}
			{text}
		</span>
	);
}
