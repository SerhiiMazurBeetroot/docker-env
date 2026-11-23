"use client";

import GlowChart from "../ui/GlowChart";

function formatBytes(bytes) {
	if (!bytes) return "0 MB";
	if (bytes < 1024 ** 3) return `${(bytes / 1024 ** 2).toFixed(0)} MB`;
	return `${(bytes / 1024 ** 3).toFixed(2)} GB`;
}

/* Summary row above the site cards: counts plus live CPU and memory totals with glow charts. */
export default function SummaryStats({ projects, history }) {
	if (!projects) return null;
	const sites = projects.length;
	const running = projects.filter((item) => item.running).length;
	const services = projects.flatMap((item) => item.services || []);
	const servicesUp = services.filter((item) => item.running).length;
	const stats = projects.filter((item) => item.running && item.resources).map((item) => item.resources);
	const cpu = stats.reduce((sum, item) => sum + (Number(item.cpuValue) || 0), 0);
	const mem = stats.reduce((sum, item) => sum + (Number(item.memValue) || 0), 0);
	const sampled = (history?.cpu || []).length;

	return (
		<section className="mb-6 grid grid-cols-2 gap-3 xl:grid-cols-4" aria-label="Summary">
			<Tile label="Sites running" value={`${running}`} suffix={` / ${sites}`}>
				<Segments on={running} total={sites} tone="ok" />
			</Tile>
			<Tile label="Containers up" value={`${servicesUp}`} suffix={` / ${services.length}`}>
				<Segments on={servicesUp} total={services.length} tone="c3" />
			</Tile>
			<Tile label="CPU" value={`${cpu.toFixed(cpu >= 10 ? 0 : 1)}%`} note={sampled > 1 ? "all sites · 5 min" : "waiting for samples"}>
				<GlowChart values={history?.cpu || []} tone="c1" height={40} />
			</Tile>
			<Tile label="Memory" value={formatBytes(mem)} note={sampled > 1 ? "all sites · 5 min" : "waiting for samples"}>
				<GlowChart values={history?.mem || []} tone="c2" height={40} />
			</Tile>
		</section>
	);
}

function Tile({ label, value, suffix = "", note = "", children }) {
	return (
		<div className="flex min-w-0 flex-col rounded-xl border border-line bg-panel/80 px-4 pb-2 pt-3">
			<p className="m-0 font-mono text-[10px] uppercase tracking-[0.14em] text-muted">{label}</p>
			<p className="m-0 mt-1 font-mono text-2xl tabular-nums text-fg">
				{value}
				{suffix ? <span className="text-base text-muted">{suffix}</span> : null}
			</p>
			{note ? <p className="m-0 text-[11px] text-muted">{note}</p> : null}
			<div className="mt-auto pt-2">{children}</div>
		</div>
	);
}

function Segments({ on, total, tone }) {
	if (!total) return <div className="h-10" />;
	const cells = Array.from({ length: Math.min(total, 24) }, (_, i) => i < Math.round((on / total) * Math.min(total, 24)));
	return (
		<div className="flex h-10 items-end gap-1 pb-1">
			{cells.map((lit, i) => (
				<span
					key={i}
					className={`h-3 flex-1 rounded-sm ${lit ? "" : "bg-raised"}`}
					style={lit ? { background: `rgb(var(--${tone}))`, boxShadow: `0 0 8px rgb(var(--${tone}) / 0.7)` } : undefined}
				/>
			))}
		</div>
	);
}
