"use client";

import { CardButton } from "./SiteCard";
import { IconPlay, IconRestart, IconStop } from "../ui/Icons";
import StatusBadge from "../ui/StatusBadge";
import UrlChip from "../ui/UrlChip";
import { waitLabel } from "../../lib/waiting";
import { dozzleContainerUrl, serviceKind } from "../../lib/projects";

export function SystemCard({ service, action, pendingExpect, onAction, onLogs, active, dozzleBase }) {
	const running = !!service.running;
	const waiting = !!action || !!pendingExpect;
	const urls = service.urls || [];
	const canAct = (service.actions || []).length > 0;
	const statusLabel = waitLabel(pendingExpect, action);
	const kind = waiting ? "waiting" : serviceKind(service);

	return (
		<article className="flex h-full flex-col rounded-xl border border-line bg-panel/90 px-4 py-3">
			<div className="mb-1 flex items-center justify-between gap-2">
				<h2 className="m-0 font-display text-base font-semibold">{service.name}</h2>
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
			{urls.length ? (
				<div className="mt-2 flex flex-wrap gap-1.5">
					{urls.map((item) => (
						<UrlChip
							key={`${service.container}-${item.key}`}
							label={item.key}
							url={item.url}
							compact
						/>
					))}
				</div>
			) : null}
			{canAct ? (
				<div className="mt-auto flex flex-wrap gap-2 pt-3">
					{running ? (
						<CardButton
							label="Stop"
							tone="stop"
							icon={<IconStop />}
							disabled={waiting}
							loading={action === "stop" || (waiting && pendingExpect === "stopped" && !action)}
							onClick={() => onAction("stop", service.id)}
						/>
					) : (
						<CardButton
							label="Start"
							tone="start"
							icon={<IconPlay />}
							disabled={waiting}
							loading={action === "start" || (waiting && pendingExpect === "running" && !action)}
							onClick={() => onAction("start", service.id)}
						/>
					)}
					<CardButton
						label="Restart"
						icon={<IconRestart />}
						disabled={!running || waiting}
						loading={action === "restart"}
						onClick={() => onAction("restart", service.id)}
					/>
				</div>
			) : null}
		</article>
	);
}
