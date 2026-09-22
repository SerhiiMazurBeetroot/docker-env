export default function HostsStatus({ hosts, busy = false, onToggle, compact = false }) {
	if (!hosts) return null;

	const siteOk = !!hosts.site;
	const extrasWanted = !!hosts.extrasWanted;
	const extrasOk = extrasWanted && hosts.extrasComplete;
	const label = !hosts.readable
		? "unknown"
		: !siteOk
			? "missing"
			: extrasWanted && !extrasOk
				? "extras missing"
				: extrasWanted
					? "extras on"
					: "ok";
	const tone = !hosts.readable
		? "text-muted"
		: !siteOk || (extrasWanted && !extrasOk)
			? "text-warn"
			: "text-ok";
	const dot = !hosts.readable
		? "bg-muted"
		: !siteOk || (extrasWanted && !extrasOk)
			? "bg-warn"
			: "bg-ok";
	const action = hosts.action;
	const actionLabel = action === "rem" ? "Remove extras" : siteOk ? "Add extras" : "Add hosts";

	return (
		<div className="inline-flex max-w-full items-center gap-1.5">
			<span
				className={`inline-flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-wider ${tone} ${
					compact ? "" : "text-[11px]"
				}`}
			>
				<span className={`h-1.5 w-1.5 rounded-full ${dot}`} aria-hidden="true" />
				hosts {label}
			</span>
			{action && onToggle ? (
				<button
					type="button"
					disabled={busy}
					title={actionLabel}
					onClick={() => onToggle(action)}
					className="rounded-md border border-line bg-raised px-1.5 py-0.5 text-[10px] font-semibold text-chip hover:border-accent/40 hover:text-accent disabled:opacity-50"
				>
					{busy ? "…" : actionLabel}
				</button>
			) : null}
		</div>
	);
}
