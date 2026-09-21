export default function HostsStatus({ hosts, busy = false, onToggle, compact = false }) {
	if (!hosts) return null;

	const siteOk = !!hosts.site;
	const extrasWanted = !!hosts.extrasWanted;
	const extrasOk = extrasWanted && hosts.extrasComplete;
	const label = !hosts.readable
		? "hosts unknown"
		: !siteOk
			? "hosts missing"
			: extrasWanted && !extrasOk
				? "extras missing"
				: extrasWanted
					? "hosts + extras"
					: "hosts ok";
	const tone = !hosts.readable
		? "border-line text-muted"
		: !siteOk || (extrasWanted && !extrasOk)
			? "border-warn/40 bg-warn/10 text-warn"
			: "border-ok/30 bg-ok/10 text-ok";
	const action = hosts.action;
	const actionLabel = action === "rem" ? "Remove extras" : siteOk ? "Add extras" : "Add hosts";

	return (
		<div className={`inline-flex max-w-full items-center gap-1 ${compact ? "" : ""}`}>
			<span className={`rounded-lg border px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider ${tone}`}>
				{label}
			</span>
			{action && onToggle ? (
				<button
					type="button"
					disabled={busy}
					title={actionLabel}
					onClick={() => onToggle(action)}
					className="rounded-lg border border-line bg-raised px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-chip hover:border-accent/40 hover:text-accent disabled:opacity-50"
				>
					{busy ? "…" : actionLabel}
				</button>
			) : null}
		</div>
	);
}
