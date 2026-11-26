"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { dozzleContainerUrl, projectKind, projectUrls, typeTone, URL_LABELS } from "../../lib/projects";
import { isBuildingProject, waitLabel } from "../../lib/waiting";
import GlowChart from "../ui/GlowChart";
import HostsStatus from "../ui/HostsStatus";
import NotRunningModal from "./NotRunningModal";
import { IconChevron, IconInfo, IconMore, IconPlay, IconRebuild, IconRestart, IconStop, IconTrash, Spinner } from "../ui/Icons";
import ErrorHint from "../ui/ErrorHint";
import ServiceChip from "../ui/ServiceChip";
import UrlChip from "../ui/UrlChip";

const TONES = ["c1", "c2", "c3", "c4"];

const STATUS_TEXT = {
	running: "text-ok",
	building: "text-warn",
	restarting: "text-warn",
	unhealthy: "text-danger",
	stopped: "text-muted",
	waiting: "text-warn",
};

const LED = {
	running: "led-on bg-ok",
	building: "bg-warn animate-pulsedot",
	restarting: "bg-warn animate-pulsedot",
	unhealthy: "bg-danger",
	stopped: "bg-muted/60",
	waiting: "bg-warn animate-pulsedot",
};

export default function SiteCard({
	project,
	index = 0,
	history,
	variant = "comfortable",
	action,
	busy = {},
	pending = {},
	detailsOpen = true,
	onToggleDetails,
	onAction,
	onLogs,
	onServiceAction,
	onOpen,
	onHosts,
	onDelete,
	selected = false,
	logContainer,
	dozzleBase,
}) {
	const running = !!project.running;
	const expect = pending[project.domain];
	const building = isBuildingProject(project);
	const waiting = !!action || !!expect || building;
	const kind = waiting ? "waiting" : projectKind(project);
	const statusLabel = waiting ? (building && !action && !expect ? "building" : waitLabel(expect, action)) : kind;
	const services = project.services || [];
	const runningServices = services.filter((item) => item.running).length;
	const resources = project.resources;
	const urls = projectUrls(project).filter((item) => item.url !== project.url);
	const hostLabel = project.domainFull || String(project.url || "").replace(/^https?:\/\//, "");
	const siteMissing = !!(project.hosts && project.hosts.readable !== false && !project.hosts.site);
	const hostsBusy = !!busy[`hosts:${project.domain}`];
	const tone = TONES[index % TONES.length];
	const cpuHistory = history?.cpu || [];
	const failed = project.notice && project.notice.ok === false && project.notice.message;
	// "delete" → "Delete failed". Shell errors without a known action read "Last command failed".
	const failedAction = String(project.notice?.action || "").trim();
	const failedLabel =
		failedAction && failedAction !== "cli"
			? `${failedAction.charAt(0).toUpperCase()}${failedAction.slice(1)} failed`
			: "Last command failed";

	// Links of a stopped project would only hit a proxy error, so a plain click asks first.
	const [blockedUrl, setBlockedUrl] = useState("");
	const offline = !running;

	function guardOpen(event, url) {
		if (!offline || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
		event.preventDefault();
		setBlockedUrl(url);
	}

	const compact = variant === "compact";
	const wide = variant === "comfortable";

	const frame = waiting
		? "neon-busy border-warn/40"
		: kind === "running"
			? "neon-glow border-ok/30"
			: kind === "unhealthy"
				? "border-danger/40"
				: "border-line";

	const primaryAction = running ? (
		<CardButton
			label="Stop"
			icon={<IconStop />}
			tone="stop"
			iconOnly={compact}
			disabled={waiting}
			loading={action === "stop"}
			onClick={() => onAction("stop", project.domain)}
		/>
	) : (
		<CardButton
			label="Start"
			icon={<IconPlay />}
			tone="start"
			iconOnly={compact}
			disabled={waiting}
			loading={action === "start" || (waiting && expect === "running" && !action)}
			onClick={() => onAction("start", project.domain)}
		/>
	);

	const secondaryActions = (
		<>
			<CardButton
				label="Restart"
				icon={<IconRestart />}
				iconOnly={compact}
				disabled={!running || waiting}
				loading={action === "restart"}
				onClick={() => onAction("restart", project.domain)}
			/>
			<CardButton
				label="Rebuild"
				icon={<IconRebuild />}
				iconOnly={compact}
				disabled={waiting}
				loading={action === "rebuild"}
				onClick={() => onAction("rebuild", project.domain)}
			/>
		</>
	);

	const menu = (
		<CardMenu
			waiting={waiting}
			deleting={action === "delete"}
			onDelete={() => onDelete?.(project.domain)}
		/>
	);

	const hostLink = project.url ? (
		// One line in every layout: a long host ends in "…" (full host on hover)
		// instead of breaking mid-word, and the ↗ always stays visible.
		// Stopped: muted, no glow; the href stays so copy link / middle-click still work.
		<>
			<a
				href={project.url}
				target="_blank"
				rel="noreferrer"
				title={offline ? `${hostLabel} · stopped, start the project to open it` : hostLabel}
				onClick={(event) => guardOpen(event, project.url)}
				className={`inline-flex min-w-0 max-w-full items-center gap-1 font-mono text-[12px] hover:underline ${
					offline ? "text-muted" : "text-glow text-accent"
				}`}
			>
				<span className="truncate">{hostLabel}</span>
				<span aria-hidden className={`shrink-0 ${offline ? "opacity-50" : ""}`}>
					↗
				</span>
			</a>
			<NotRunningModal
				open={!!blockedUrl}
				project={project.domain}
				url={blockedUrl}
				starting={waiting}
				onStart={() => onAction("start", project.domain)}
				onClose={() => setBlockedUrl("")}
			/>
		</>
	) : (
		<span className="truncate font-mono text-[12px] text-muted">{hostLabel || "No domain"}</span>
	);

	// Last failure: a red icon next to the status, full message on hover/focus/tap.
	const errorHint = failed ? <ErrorHint label={failedLabel} message={project.notice.message} /> : null;

	const alerts = (
		<>
			{siteMissing ? (
				<div className="flex items-center gap-2 rounded-lg border border-warn/30 bg-warn/10 px-2.5 py-1.5 text-[12px] text-warn">
					<span className="min-w-0 flex-1">This domain is missing from your hosts file.</span>
					<button
						type="button"
						disabled={hostsBusy}
						onClick={() => onHosts?.("add", project.domain)}
						className="shrink-0 rounded-md border border-warn/40 px-2 py-0.5 font-semibold hover:bg-warn/15 disabled:opacity-50"
					>
						{hostsBusy ? "Adding…" : "Add hosts"}
					</button>
				</div>
			) : null}
		</>
	);

	const hasDetails = !!(services.length || urls.length || project.hosts?.site);
	const details =
		(wide || detailsOpen) && hasDetails ? (
			<div className="grid gap-3">
				{services.length ? (
					<div>
						<p className="m-0 mb-1.5 font-mono text-[10px] uppercase tracking-[0.12em] text-muted">
							Containers · click for logs
						</p>
						<div className="flex flex-wrap gap-1.5">
							{services.map((item) => {
								const serviceName = item.service || item.name;
								const containerName = item.name || item.service;
								const busyKey = `svc:${project.domain}:${serviceName}`;
								return (
									<ServiceChip
										key={`${project.domain}-${serviceName}`}
										service={serviceName}
										name={containerName}
										domain={project.domain}
										running={!!item.running}
										state={item.state}
										health={item.health}
										status={item.status}
										active={logContainer === containerName}
										busy={busy?.[busyKey] || ""}
										waiting={!!busy?.[busyKey] || !!pending[busyKey] || !!expect || building}
										dozzleUrl={item.state === "missing" ? "" : dozzleContainerUrl(containerName, dozzleBase)}
										onLogs={() => onLogs?.(containerName, serviceName)}
										onStart={() => onServiceAction?.("start", project.domain, serviceName)}
										onStop={() => onServiceAction?.("stop", project.domain, serviceName)}
									/>
								);
							})}
						</div>
					</div>
				) : null}
				{urls.length || project.hosts?.site ? (
					<div className="flex flex-wrap items-center gap-1.5">
						{urls.map((item) => (
							<UrlChip
								key={`${project.domain}-${item.key}`}
								label={URL_LABELS[item.key] || item.key}
								url={item.url}
								compact
								offline={offline}
								onOpen={(event) => guardOpen(event, item.url)}
							/>
						))}
						{project.hosts?.site ? (
							<HostsStatus
								hosts={project.hosts}
								compact
								busy={hostsBusy}
								onToggle={(next) => onHosts?.(next, project.domain)}
							/>
						) : null}
					</div>
				) : null}
			</div>
		) : null;

	// The project drawer (paths, volumes, env keys) opens only from this button,
	// so a stray click on the card never pops it open.
	const infoButton = onOpen ? (
		<button
			type="button"
			onClick={() => onOpen(selected ? "" : project.domain)}
			aria-pressed={selected}
			title="Project info: paths, volumes, env keys"
			aria-label="Project info: paths, volumes, env keys"
			className={`inline-flex h-8 w-8 items-center justify-center rounded-lg hover:bg-fg/10 hover:text-fg ${
				selected ? "bg-accent/15 text-accent" : "text-muted"
			}`}
		>
			<IconInfo />
		</button>
	) : null;

	const detailsToggle =
		onToggleDetails && hasDetails && !wide ? (
			<button
				type="button"
				onClick={onToggleDetails}
				aria-expanded={detailsOpen}
				title={detailsOpen ? "Hide containers and links" : "Show containers and links"}
				aria-label={detailsOpen ? "Hide containers and links" : "Show containers and links"}
				className="inline-flex h-8 w-8 items-center justify-center rounded-lg text-muted hover:bg-fg/10 hover:text-fg"
			>
				<IconChevron className={`h-3.5 w-3.5 transition ${detailsOpen ? "rotate-180" : ""}`} />
			</button>
		) : null;

	if (compact) {
		return (
			<article
				aria-label={`${project.domain}, ${statusLabel}`}
				className={`relative flex min-w-0 flex-col gap-2 rounded-xl border bg-panel/90 px-3 py-2 transition hover:border-accent/40 ${frame} ${
					selected ? "ring-1 ring-accent/50" : ""
				}`}
			>
				<div className="flex flex-wrap items-center gap-x-4 gap-y-2">
					<div className="flex min-w-0 flex-[1_1_16rem] items-center gap-2.5">
						<span className={`led shrink-0 ${LED[kind] || LED.stopped}`} title={statusLabel} />
						<div className="flex min-w-0 flex-col">
							<span className="truncate font-display text-[14px] font-semibold leading-tight text-fg">{project.domain}</span>
							{hostLink}
						</div>
					</div>
					<span className={`shrink-0 rounded-md px-2 py-0.5 font-mono text-[11px] font-medium ${typeTone(project.type)}`}>
						{project.type || "site"}
					</span>
					<span className="inline-flex w-24 shrink-0 items-center gap-1">
						<span className={`text-[12px] font-semibold capitalize ${STATUS_TEXT[kind] || "text-muted"}`}>
							{statusLabel}
						</span>
						{errorHint}
					</span>
					<div className="flex shrink-0 items-center gap-4 font-mono text-[12px] tabular-nums">
						<InlineMetric label="CPU" value={running && resources ? resources.cpu : "—"} warn={resources?.high} />
						<InlineMetric label="MEM" value={running && resources ? resources.mem : "—"} warn={resources?.high} />
						{services.length ? (
							<span className="text-muted" title="Running containers">
								{runningServices}/{services.length}
							</span>
						) : null}
					</div>
					<div className="ml-auto flex shrink-0 items-center gap-1">
						{primaryAction}
						{secondaryActions}
						{detailsToggle}
						{infoButton}
						{menu}
					</div>
				</div>
				{siteMissing ? <div className="grid gap-1.5">{alerts}</div> : null}
				{details ? <div className="border-t border-line pb-1 pt-2.5">{details}</div> : null}
				{waiting ? (
					<span className="pointer-events-none absolute inset-0 overflow-hidden rounded-[inherit]">
						<span className="absolute inset-x-0 bottom-0 h-[2px] overflow-hidden bg-raised">
							<span className="progress-slide block h-full w-2/5 bg-warn shadow-[0_0_10px_rgb(var(--warn))]" />
						</span>
					</span>
				) : null}
			</article>
		);
	}

	const chart = (
		<div>
			<GlowChart values={running ? cpuHistory : []} tone={running ? tone : "muted"} height={wide ? 96 : 40} grid />
			<p className="m-0 mt-1 font-mono text-[10px] uppercase tracking-[0.12em] text-muted">
				{running ? (cpuHistory.length > 1 ? "CPU · last 5 min" : "CPU · collecting samples…") : "Stopped"}
			</p>
		</div>
	);

	if (wide) {
		return (
			<article
				aria-label={`${project.domain}, ${statusLabel}`}
				className={`relative grid min-w-0 gap-x-6 gap-y-4 rounded-2xl border bg-panel/90 p-5 transition hover:border-accent/40 lg:grid-cols-[minmax(0,1fr)_minmax(0,1.15fr)] ${frame} ${
					selected ? "ring-1 ring-accent/50" : ""
				}`}
			>
				<div className="flex min-w-0 flex-col gap-4">
					<header className="flex items-start gap-3">
						<span className={`led mt-2 shrink-0 ${LED[kind] || LED.stopped}`} />
						<div className="min-w-0 flex-1">
							<h3 className="m-0 break-words font-display text-[20px] font-semibold leading-snug text-fg">
								{project.domain}
							</h3>
							{hostLink}
						</div>
						<div className="flex shrink-0 flex-col items-end gap-1">
							<span className={`rounded-md px-2 py-0.5 font-mono text-[11px] font-medium ${typeTone(project.type)}`}>
								{project.type || "site"}
							</span>
							{project.guide ? (
								<Link href={project.guide} className="text-[11px] text-muted hover:text-accent">
									Guide
								</Link>
							) : null}
						</div>
					</header>

					<div className="flex items-center gap-2 text-[12px]">
						<span className={`font-semibold capitalize ${STATUS_TEXT[kind] || "text-muted"}`}>{statusLabel}</span>
						{errorHint}
						{services.length ? (
							<span className="font-mono text-muted">
								· {runningServices}/{services.length} containers
							</span>
						) : null}
					</div>

					{waiting ? (
						<div className="h-[3px] overflow-hidden rounded-full bg-raised">
							<span className="progress-slide block h-full w-2/5 rounded-full bg-warn shadow-[0_0_10px_rgb(var(--warn))]" />
						</div>
					) : null}

					{alerts}

					<div className="grid grid-cols-3 gap-2">
						<Metric boxed label="CPU" value={running && resources ? resources.cpu : "—"} warn={resources?.high} />
						<Metric boxed label="Memory" value={running && resources ? resources.mem : "—"} warn={resources?.high} />
						<Metric
							boxed
							label="Mem %"
							value={running && resources?.memPerc ? resources.memPerc : "—"}
							hint="Share of the memory Docker can use"
						/>
					</div>

					<footer className="mt-auto flex flex-wrap items-center gap-2 pt-1">
						{primaryAction}
						{secondaryActions}
						<div className="ml-auto flex items-center gap-1">
							{detailsToggle}
							{infoButton}
							{menu}
						</div>
					</footer>
				</div>

				<div className="flex min-w-0 flex-col gap-4 lg:border-l lg:border-line lg:pl-6">
					{chart}
					{details}
				</div>
			</article>
		);
	}

	return (
		<article
			aria-label={`${project.domain}, ${statusLabel}`}
			className={`relative flex min-w-0 flex-col gap-3 rounded-2xl border bg-panel/90 p-3.5 transition hover:border-accent/40 ${frame} ${
				selected ? "ring-1 ring-accent/50" : ""
			}`}
		>
			<header className="flex items-start gap-2.5">
				<span className={`led mt-1.5 shrink-0 ${LED[kind] || LED.stopped}`} />
				<div className="min-w-0 flex-1">
					<h3 className="m-0 truncate font-display text-[15px] font-semibold leading-snug text-fg">{project.domain}</h3>
					<div className="flex min-w-0">{hostLink}</div>
				</div>
				<span className={`shrink-0 rounded-md px-2 py-0.5 font-mono text-[11px] font-medium ${typeTone(project.type)}`}>
					{project.type || "site"}
				</span>
			</header>

			<div className="flex items-center gap-2 text-[12px]">
				<span className={`font-semibold capitalize ${STATUS_TEXT[kind] || "text-muted"}`}>{statusLabel}</span>
				{errorHint}
				{services.length ? (
					<span className="ml-auto font-mono text-muted">
						{runningServices}/{services.length} containers
					</span>
				) : null}
			</div>

			{waiting ? (
				<div className="h-[3px] overflow-hidden rounded-full bg-raised">
					<span className="progress-slide block h-full w-2/5 rounded-full bg-warn shadow-[0_0_10px_rgb(var(--warn))]" />
				</div>
			) : null}

			{alerts}

			<div className="flex items-end gap-3">
				<div className="grid shrink-0 grid-cols-2 gap-3">
					<Metric label="CPU" value={running && resources ? resources.cpu : "—"} warn={resources?.high} />
					<Metric label="Mem" value={running && resources ? resources.mem : "—"} warn={resources?.high} />
				</div>
				<div className="min-w-0 flex-1" title={running ? "CPU · last 5 min" : "Stopped"}>
					<GlowChart values={running ? cpuHistory : []} tone={running ? tone : "muted"} height={34} />
				</div>
			</div>

			{details}

			<footer className="mt-auto flex items-center gap-1.5 border-t border-line pt-3">
				{primaryAction}
				<CardButton
					label="Restart"
					icon={<IconRestart />}
					iconOnly
					disabled={!running || waiting}
					loading={action === "restart"}
					onClick={() => onAction("restart", project.domain)}
				/>
				<CardButton
					label="Rebuild"
					icon={<IconRebuild />}
					iconOnly
					disabled={waiting}
					loading={action === "rebuild"}
					onClick={() => onAction("rebuild", project.domain)}
				/>
				<div className="ml-auto flex items-center gap-1">
					{detailsToggle}
					{infoButton}
					{menu}
				</div>
			</footer>
		</article>
	);
}

function Metric({ label, value, warn = false, hint = "", boxed = false }) {
	return (
		<div className={`min-w-0 ${boxed ? "rounded-xl border border-line bg-raised/40 px-3 py-2" : ""}`} title={hint || undefined}>
			<p className="m-0 font-mono text-[10px] uppercase tracking-[0.12em] text-muted">{label}</p>
			<p className={`m-0 truncate font-mono text-[15px] tabular-nums ${warn ? "text-warn" : "text-fg"}`}>{value}</p>
		</div>
	);
}

function InlineMetric({ label, value, warn = false }) {
	return (
		<span className="inline-flex items-baseline gap-1.5">
			<span className="text-[10px] uppercase tracking-[0.12em] text-muted">{label}</span>
			<span className={`w-14 truncate ${warn ? "text-warn" : "text-fg"}`}>{value}</span>
		</span>
	);
}

export function CardButton({ label, icon, tone = "", iconOnly = false, disabled, loading, onClick }) {
	const tones = {
		start: "border-ok/50 text-ok hover:bg-ok/10 hover:shadow-[0_0_14px_-4px_rgb(var(--ok)/0.8)]",
		stop: "border-danger/50 text-danger hover:bg-danger/10 hover:shadow-[0_0_14px_-4px_rgb(var(--danger)/0.8)]",
	};
	return (
		<button
			type="button"
			disabled={disabled}
			onClick={onClick}
			title={iconOnly ? label : undefined}
			aria-label={iconOnly ? label : undefined}
			className={`inline-flex h-8 items-center justify-center gap-1.5 rounded-lg border text-[12px] ${iconOnly ? "w-8" : "px-2.5"} font-semibold transition disabled:pointer-events-none disabled:opacity-40 ${
				tones[tone] || "border-line text-fg hover:border-accent/50 hover:text-accent"
			}`}
		>
			{loading ? <Spinner className="h-3.5 w-3.5" /> : icon}
			{iconOnly ? null : label}
		</button>
	);
}

function CardMenu({ waiting, deleting, onDelete }) {
	const [open, setOpen] = useState(false);
	const root = useRef(null);

	useEffect(() => {
		if (!open) return undefined;
		function onPointer(event) {
			if (!root.current?.contains(event.target)) setOpen(false);
		}
		function onKey(event) {
			if (event.key === "Escape") setOpen(false);
		}
		window.addEventListener("pointerdown", onPointer);
		window.addEventListener("keydown", onKey);
		return () => {
			window.removeEventListener("pointerdown", onPointer);
			window.removeEventListener("keydown", onKey);
		};
	}, [open]);

	return (
		<div className="relative" ref={root}>
			<button
				type="button"
				title="More actions"
				aria-label="More actions"
				aria-haspopup="menu"
				aria-expanded={open}
				onClick={() => setOpen((value) => !value)}
				className="inline-flex h-8 w-8 items-center justify-center rounded-lg text-muted hover:bg-fg/10 hover:text-fg"
			>
				{deleting ? <Spinner className="h-3.5 w-3.5" /> : <IconMore />}
			</button>
			{open ? (
				<div
					role="menu"
					className="absolute bottom-[calc(100%+0.35rem)] right-0 z-40 min-w-[11rem] overflow-hidden rounded-xl border border-line bg-panel py-1 shadow-card"
				>
					<button
						type="button"
						role="menuitem"
						disabled={waiting}
						onClick={() => {
							setOpen(false);
							onDelete();
						}}
						className="flex w-full items-center gap-2 px-3 py-2 text-left text-[13px] font-semibold text-danger hover:bg-danger/10 disabled:pointer-events-none disabled:opacity-40"
					>
						<IconTrash />
						Delete
					</button>
				</div>
			) : null}
		</div>
	);
}
