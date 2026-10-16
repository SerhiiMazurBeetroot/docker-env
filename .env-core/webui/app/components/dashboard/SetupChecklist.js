"use client";

export default function SetupChecklist({ setup, loading, busy = {}, onHosts }) {
	const items = setup?.items || [];
	if (loading || !items.length) return null;

	const attention = items.filter((item) => !item.ok);
	if (!attention.length) return null;

	const hosts = attention.find((item) => item.id === "hosts");
	const site = hosts?.sites?.length === 1 ? hosts.sites[0] : null;
	const hostsBusy = site ? !!busy[`hosts:${site.domain}`] : false;

	return (
		<section
			className="mb-2 flex flex-wrap items-center gap-x-3 gap-y-2 rounded-xl border border-danger/35 bg-panel/80 px-3 py-2"
			aria-label="Setup"
		>
			<span className="text-[10px] font-bold uppercase tracking-wider text-muted">Setup</span>
			{attention.map((item) => (
				<span key={item.id} className="inline-flex min-w-0 items-center gap-2 text-[12px]">
					<span className="h-1.5 w-1.5 shrink-0 rounded-full bg-danger" aria-hidden />
					<span className="font-semibold text-fg">{item.label}</span>
					<span className="text-danger">{item.hint}</span>
				</span>
			))}
			{site ? (
				<button
					type="button"
					disabled={hostsBusy || !onHosts}
					onClick={() => onHosts("add", site.domain)}
					className="ml-auto shrink-0 rounded-lg border border-line bg-raised px-2.5 py-1 text-[12px] font-semibold text-fg hover:border-accent/40 hover:text-accent disabled:opacity-50"
				>
					{hostsBusy ? "Adding…" : "Add hosts"}
				</button>
			) : null}
		</section>
	);
}
