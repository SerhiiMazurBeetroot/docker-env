export default function ResourceGlance({ resources, compact = false }) {
	if (!resources) return null;

	const tone = resources.high ? "border-warn/40 bg-warn/10 text-warn" : "border-line bg-raised text-chip";

	return (
		<span
			title={resources.high ? "High CPU or RAM — Elastic-sized footprint" : "Sampled docker stats"}
			className={`inline-flex items-center gap-1.5 rounded-lg border font-mono w-max ${
				compact ? "px-1.5 py-0.5 text-[10px]" : "px-2 py-1 text-[11px]"
			} ${tone}`}
		>
			<span>{resources.cpu} CPU</span>
			<span className="text-muted">·</span>
			<span>
				{resources.mem}
				{resources.memPerc ? ` (${resources.memPerc})` : ""} RAM
			</span>
		</span>
	);
}
