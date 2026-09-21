"use client";

import { useState } from "react";
import ActionButton from "../ui/ActionButton";
import { IconChevron, IconPlay, IconRestart, IconStop } from "../ui/Icons";
import { SystemSkeleton } from "../ui/Skeleton";
import StatusBadge from "../ui/StatusBadge";
import UrlChip from "../ui/UrlChip";
import { waitLabel } from "../../lib/waiting";
import { dozzleContainerUrl, serviceKind } from "../../lib/projects";

export default function SystemSection({ services, loading, busy, pending = {}, onAction, onLogs, logContainer, dozzleBase }) {
	const [open, setOpen] = useState(false);

	if (loading) {
		return <SystemSkeleton />;
	}

	if (!services.length) return null;

	const unhealthy = services.some((service) => !service.running);
	const runningCount = services.filter((service) => service.running).length;

	return (
		<section
			className={`mb-4 rounded-xl border bg-panel/80 ${unhealthy ? "border-danger/35" : "border-line"}`}
		>
			<button
				type="button"
				aria-expanded={open}
				onClick={() => setOpen((value) => !value)}
				className="flex w-full flex-wrap items-center gap-2 px-3 py-2 text-left"
			>
				<span className="text-[10px] font-bold uppercase tracking-wider text-muted">System</span>
				{services.map((service) => (
					<span
						key={service.id || service.container}
						className="inline-flex items-center gap-1.5 text-[12px] font-semibold text-fg"
					>
						<span
							className={`h-1.5 w-1.5 rounded-full ${
								busy[`system:${service.id}`] || pending[`system:${service.id}`]
									? "bg-accent animate-pulsedot"
									: service.running
										? "bg-ok"
										: "bg-danger"
							}`}
						/>
						{service.name}
					</span>
				))}
				<span className="ml-auto inline-flex items-center gap-1 rounded-lg border border-line bg-raised px-2 py-1 text-[12px] font-semibold text-fg">
					{open ? "Hide services" : "Show services"}
					<span className="font-medium text-muted">
						{runningCount}/{services.length}
					</span>
					<IconChevron className={`h-3 w-3 text-muted transition ${open ? "rotate-180" : ""}`} />
				</span>
			</button>
			{open ? (
				<div className="grid gap-2 border-t border-line px-3 py-3 sm:grid-cols-3">
					{services.map((service) => (
						<SystemCard
							key={service.id || service.container}
							service={service}
							action={busy[`system:${service.id}`]}
							pendingExpect={pending[`system:${service.id}`]}
							onAction={onAction}
							onLogs={onLogs}
							active={logContainer === service.container}
							dozzleBase={dozzleBase}
						/>
					))}
				</div>
			) : null}
		</section>
	);
}

function SystemCard({ service, action, pendingExpect, onAction, onLogs, active, dozzleBase }) {
	const running = !!service.running;
	const waiting = !!action || !!pendingExpect;
	const urls = service.urls || [];
	const canAct = (service.actions || []).length > 0;
	const statusLabel = waitLabel(pendingExpect, action);
	const kind = waiting ? "waiting" : serviceKind(service);

	return (
		<article className="rounded-lg border border-line bg-raised/60 px-3 py-2.5">
			<div className="mb-1 flex items-center justify-between gap-2">
				<h2 className="m-0 text-sm font-extrabold tracking-tight">{service.name}</h2>
				<StatusBadge
					running={running}
					compact
					waiting={waiting}
					label={waiting ? statusLabel : kind}
					kind={kind}
				/>
			</div>
			{service.container ? (
				<>
					<button
						type="button"
						className={`m-0 block w-full truncate text-left font-mono text-[11px] ${
							active ? "text-accent" : "text-muted hover:text-accent"
						}`}
						onClick={() => onLogs?.(service.container, service.name)}
					>
						{service.container}
					</button>
					<a
						href={dozzleContainerUrl(service.container, dozzleBase)}
						target="_blank"
						rel="noreferrer"
						className="mt-0.5 inline-block text-[10px] font-semibold uppercase tracking-wider text-muted hover:text-accent"
					>
						Open in Dozzle
					</a>
				</>
			) : null}
			<div className="mt-2 flex flex-wrap gap-1.5">
				{urls.length === 0 ? (
					<span className="text-xs text-muted">No port</span>
				) : (
					urls.map((item) => (
						<UrlChip
							key={`${service.container}-${item.key}`}
							label={item.key}
							url={item.url}
							compact
						/>
					))
				)}
			</div>
			{canAct ? (
				<div className="mt-3 flex flex-wrap gap-1 rounded-lg border border-line bg-fg/5 p-1">
					<ActionButton
						label="Start"
						tone="start"
						size="sm"
						icon={<IconPlay />}
						disabled={running || waiting}
						loading={action === "start" || (waiting && pendingExpect === "running" && !action)}
						onClick={() => onAction("start", service.id)}
					/>
					<ActionButton
						label="Restart"
						tone="restart"
						size="sm"
						icon={<IconRestart />}
						disabled={!running || waiting}
						loading={action === "restart"}
						onClick={() => onAction("restart", service.id)}
					/>
					<ActionButton
						label="Stop"
						tone="stop"
						size="sm"
						icon={<IconStop />}
						disabled={!running || waiting}
						loading={action === "stop" || (waiting && pendingExpect === "stopped" && !action)}
						onClick={() => onAction("stop", service.id)}
					/>
				</div>
			) : null}
		</article>
	);
}
