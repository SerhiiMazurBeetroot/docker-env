export default function ResourceGlance({ resources, compact = false, plain = false }) {
	if (!resources) return null;

	const valueClass = resources.high ? "text-warn" : "text-chip";
	const ram = `${resources.mem}${resources.memPerc ? ` (${resources.memPerc})` : ""}`;

	const metrics = (
		<>
			<span className="inline-flex items-baseline gap-1">
				<span className="text-[9px] font-bold uppercase tracking-wider text-muted">CPU</span>
				<span className={`font-mono ${compact ? "text-[11px]" : "text-xs"} ${valueClass}`}>
					{resources.cpu}
				</span>
			</span>
			<span className="inline-flex items-baseline gap-1">
				<span className="text-[9px] font-bold uppercase tracking-wider text-muted">RAM</span>
				<span className={`font-mono ${compact ? "text-[11px]" : "text-xs"} ${valueClass}`}>{ram}</span>
			</span>
		</>
	);

	if (plain) {
		return (
			<span
				title={resources.high ? "High CPU or RAM — Elastic-sized footprint" : "Sampled docker stats"}
				className="inline-flex items-center gap-3"
			>
				{metrics}
			</span>
		);
	}

	return (
		<span
			title={resources.high ? "High CPU or RAM — Elastic-sized footprint" : "Sampled docker stats"}
			className={`inline-flex w-max items-center gap-3 rounded-lg border ${
				compact ? "px-1.5 py-0.5" : "px-2 py-1"
			} ${resources.high ? "border-warn/40 bg-warn/10" : "border-line bg-raised"}`}
		>
			{metrics}
		</span>
	);
}
