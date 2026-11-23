"use client";

import { SystemSkeleton } from "../ui/Skeleton";
import { IconCheck } from "../ui/Icons";
import { SystemCard } from "./SystemSection";

/* System page: one card per shared service, plus the full setup checklist. */
export default function SystemView({ services = [], loading, setup, busy = {}, pending = {}, onAction, onLogs, onHosts, logContainer, dozzleBase }) {
	const items = setup?.items || [];

	return (
		<div className="grid gap-6">
			{loading ? (
				<SystemSkeleton />
			) : (
				<section className="grid grid-cols-[repeat(auto-fill,minmax(min(100%,16rem),1fr))] gap-4" aria-label="Services">
					{services.map((service) => (
						<div
							key={service.id || service.container}
							className={`rounded-xl ${service.running ? "neon-glow" : ""}`}
						>
							<SystemCard
								service={service}
								action={busy[`system:${service.id}`]}
								pendingExpect={pending[`system:${service.id}`]}
								onAction={onAction}
								onLogs={onLogs}
								active={logContainer === service.container}
								dozzleBase={dozzleBase}
							/>
						</div>
					))}
				</section>
			)}

			{items.length ? (
				<section className="rounded-2xl border border-line bg-panel/80" aria-label="Setup checklist">
					<h3 className="m-0 border-b border-line px-4 py-3 font-display text-base font-semibold">Setup checklist</h3>
					<ul className="m-0 list-none divide-y divide-line p-0">
						{items.map((item) => {
							const site = item.id === "hosts" && item.sites?.length === 1 ? item.sites[0] : null;
							const hostsBusy = site ? !!busy[`hosts:${site.domain}`] : false;
							return (
								<li key={item.id} className="flex flex-wrap items-center gap-3 px-4 py-3 text-sm">
									<span
										className={`grid h-6 w-6 shrink-0 place-items-center rounded-full ${
											item.ok ? "bg-ok/15 text-ok" : "bg-danger/15 text-danger"
										}`}
									>
										{item.ok ? <IconCheck className="h-3.5 w-3.5" /> : "!"}
									</span>
									<span className="font-semibold">{item.label}</span>
									<span className={item.ok ? "text-muted" : "text-danger"}>{item.hint}</span>
									{site && onHosts ? (
										<button
											type="button"
											disabled={hostsBusy}
											onClick={() => onHosts("add", site.domain)}
											className="ml-auto rounded-lg border border-line px-2.5 py-1 text-[12px] font-semibold hover:border-accent/50 hover:text-accent disabled:opacity-50"
										>
											{hostsBusy ? "Adding…" : "Add hosts"}
										</button>
									) : null}
								</li>
							);
						})}
					</ul>
				</section>
			) : null}
		</div>
	);
}
