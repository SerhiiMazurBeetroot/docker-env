import { useEffect, useRef, useState } from "react";
import {
	dozzleContainerUrl,
	groupProjectsByType,
	projectKind,
	projectUrls,
	typeTone,
	URL_LABELS,
} from "../../lib/projects";
import { isBuildingProject, waitLabel } from "../../lib/waiting";
import { useDisplay } from "../display/DisplayProvider";
import ActionButton from "../ui/ActionButton";
import HostsStatus from "../ui/HostsStatus";
import { IconChevron, IconMore, IconPlay, IconRebuild, IconRestart, IconStop, IconTrash, Spinner } from "../ui/Icons";
import ResourceGlance from "../ui/ResourceGlance";
import ServiceChip from "../ui/ServiceChip";
import { ProjectSkeleton } from "../ui/Skeleton";
import StatusBadge from "../ui/StatusBadge";
import UrlChip from "../ui/UrlChip";

export default function ProjectList({
	projects,
	visible,
	error,
	busy,
	pending = {},
	onAction,
	onLogs,
	onServiceAction,
	onOpen,
	onHosts,
	onDelete,
	selectedDomain,
	logContainer,
	dozzleBase,
}) {
	const { density, expandAll } = useDisplay();
	const compact = density === "compact";
	const grid = density === "grid";
	const [overrides, setOverrides] = useState({});

	useEffect(() => {
		setOverrides({});
	}, [expandAll]);

	function isOpen(domain) {
		return Object.prototype.hasOwnProperty.call(overrides, domain) ? overrides[domain] : expandAll;
	}

	function toggleOpen(domain) {
		setOverrides(current => ({
			...current,
			[domain]: !(Object.prototype.hasOwnProperty.call(current, domain) ? current[domain] : expandAll),
		}));
	}

	if (error) {
		return <div className="rounded-2xl border border-danger/30 bg-danger/10 px-5 py-4 text-danger">{error}</div>;
	}

	if (projects == null) {
		return <ProjectSkeleton compact={compact} grid={grid} />;
	}

	if (visible.length === 0) {
		return (
			<div className="rounded-2xl border border-dashed border-line bg-panel/60 px-6 py-12 text-center text-muted">
				{projects.length === 0
					? "No projects in instances.log yet. Use New project to create one."
					: "No projects match this filter."}
			</div>
		);
	}

	const card = project => (
		<ProjectCard
			key={project.domain}
			layout={density}
			project={project}
			action={busy[project.domain]}
			busy={busy}
			pending={pending}
			onAction={onAction}
			onLogs={onLogs}
			onServiceAction={onServiceAction}
			onOpen={onOpen}
			onHosts={onHosts}
			onDelete={onDelete}
			selected={selectedDomain === project.domain}
			servicesOpen={isOpen(project.domain)}
			onToggleServices={() => toggleOpen(project.domain)}
			logContainer={logContainer}
			dozzleBase={dozzleBase}
		/>
	);

	const groups = groupProjectsByType(visible);
	const listClass = compact ? "grid gap-1.5" : grid ? "grid gap-3 sm:grid-cols-2 xl:grid-cols-3" : "grid gap-3";

	return (
		<div className={compact ? "grid gap-4" : "grid gap-6"}>
			{groups.map(group => (
				<section key={group.type}>
					<div className={`flex items-center gap-2 ${compact ? "mb-1.5" : "mb-2"}`}>
						<span
							className={`rounded-full px-2.5 py-0.5 text-[11px] font-semibold ${typeTone(group.type)}`}
						>
							{group.type}
						</span>
						<span className="text-[11px] text-muted">
							{group.items.length} project{group.items.length === 1 ? "" : "s"}
						</span>
					</div>
					<div className={listClass}>{group.items.map(card)}</div>
				</section>
			))}
		</div>
	);
}

function ProjectCard({
	layout = "comfortable",
	project,
	action,
	busy,
	pending = {},
	onAction,
	onLogs,
	onServiceAction,
	onOpen,
	onHosts,
	onDelete,
	selected = false,
	servicesOpen = true,
	onToggleServices,
	logContainer,
	dozzleBase,
}) {
	const compact = layout === "compact";
	const grid = layout === "grid";
	const running = !!project.running;
	const expect = pending[project.domain];
	const building = isBuildingProject(project);
	const waiting = !!action || !!expect || building;
	const urls = projectUrls(project);
	const services = project.services || [];
	const kind = waiting ? "waiting" : projectKind(project);
	const statusLabel = building && !action && !expect ? "building" : waitLabel(expect, action);

	function openDetails(event) {
		if (event.target.closest("a,button")) return;
		onOpen?.(project.domain);
	}

	const actions = (
		<ActionRow
			compact
			running={running}
			waiting={waiting}
			action={action}
			expect={expect}
			onAction={onAction}
			onDelete={onDelete}
			domain={project.domain}
		/>
	);

	return (
		<article
			role="button"
			tabIndex={0}
			onClick={openDetails}
			onKeyDown={event => {
				if (event.target !== event.currentTarget) return;
				if (event.key === "Enter" || event.key === " ") {
					event.preventDefault();
					onOpen?.(project.domain);
				}
			}}
			title="Open project details"
			className={`relative cursor-pointer border border-line bg-panel/90 shadow-card ${
				compact ? "rounded-xl px-3 py-2" : grid ? "flex h-full flex-col rounded-2xl p-3.5" : "rounded-2xl p-4"
			} ${running && !waiting && kind === "running" ? "shadow-glow" : ""} ${
				waiting ? "ring-1 ring-accent/25" : ""
			} ${selected ? "ring-1 ring-accent/40" : ""} hover:border-accent/30`}
		>
			{waiting ? (
				<div
					className={`pointer-events-none absolute inset-0 bg-accent/5 ${compact ? "rounded-xl" : "rounded-2xl"}`}
				/>
			) : null}
			<div className={`relative flex min-h-0 flex-1 flex-col ${compact ? "gap-1.5" : "gap-2.5"}`}>
				<div className="flex items-start gap-2">
					<div className="min-w-0 flex-1">
						<div className="flex flex-wrap items-center gap-1.5">
							<StatusBadge
								running={running}
								compact
								waiting={waiting}
								label={waiting ? statusLabel : kind}
								kind={kind}
							/>
						</div>
						<h2 className="m-0 truncate font-extrabold tracking-tight text-fg text-sm">{project.domain}</h2>
						<p className="m-0 truncate font-mono text-[10px] text-muted">{project.domainFull || "—"}</p>
					</div>
					<div className="flex shrink-0 items-start gap-1">
						{services.length ? (
							<div className="flex flex-nowrap gap-1 rounded-xl border border-line bg-fg/5 shrink-0 p-1">
								<button
									type="button"
									title={servicesOpen ? "Hide services" : "Show services"}
									aria-expanded={servicesOpen}
									onClick={event => {
										event.stopPropagation();
										onToggleServices?.();
									}}
									className="inline-flex h-7 w-20 items-center justify-center rounded-lg border border-line bg-fg/5 text-muted hover:text-fg"
								>
									<IconChevron className={`h-3 w-3 transition ${servicesOpen ? "rotate-180" : ""}`} />
								</button>
							</div>
						) : null}
						{actions}
					</div>
				</div>
				{servicesOpen ? (
					<>
						<ProjectMeta
							project={project}
							urls={urls}
							layout={layout}
							hostsBusy={!!busy[`hosts:${project.domain}`]}
							onHosts={onHosts}
						/>
						<ServiceRow
							project={project}
							services={services}
							busy={busy}
							pending={pending}
							expect={expect}
							building={building}
							onLogs={onLogs}
							onServiceAction={onServiceAction}
							logContainer={logContainer}
							dozzleBase={dozzleBase}
						/>
					</>
				) : null}
			</div>
		</article>
	);
}

function ProjectMeta({ project, urls, layout = "comfortable", hostsBusy, onHosts }) {
	const compactChips = layout !== "comfortable";
	const stacked = layout === "grid";
	const hasStats = layout === "comfortable" && !!project.resources;
	const hasHosts = !!project.hosts;
	const hasUrls = urls.length > 0;

	if (!hasStats && !hasHosts && !hasUrls && compactChips) return null;

	return (
		<div className="overflow-hidden rounded-xl border border-line bg-fg/5">
			<div
				className={
					stacked
						? "flex flex-col divide-y divide-line"
						: "flex flex-col divide-y divide-line sm:flex-row sm:items-center sm:divide-x sm:divide-y-0"
				}
			>
				{hasStats ? (
					<div className="flex shrink-0 items-center px-2.5 py-1.5">
						<ResourceGlance resources={project.resources} plain />
					</div>
				) : null}
				<div className="flex min-w-0 flex-1 flex-wrap items-center gap-1 px-2 py-1.5">
					{!hasUrls && layout === "comfortable" ? (
						<span className="text-sm text-muted">No URLs yet</span>
					) : null}
					{urls.map(item => (
						<UrlChip
							key={`${project.domain}-${item.key}`}
							label={URL_LABELS[item.key] || item.key}
							url={item.url}
							compact={compactChips}
						/>
					))}
				</div>
				{hasHosts ? (
					<div className="flex shrink-0 items-center px-2.5 py-1.5">
						<HostsStatus
							hosts={project.hosts}
							compact={compactChips}
							busy={hostsBusy}
							onToggle={action => onHosts?.(action, project.domain)}
						/>
					</div>
				) : null}
			</div>
		</div>
	);
}

function ActionRow({ compact = false, running, waiting, action, expect, onAction, onDelete, domain }) {
	const extraClass = "hidden md:inline-flex";
	const startLoading = action === "start" || (waiting && expect === "running" && !action);
	const stopLoading = action === "stop" || (waiting && expect === "stopped" && action === "stop");

	return (
		<div
			className={`flex flex-nowrap gap-1 rounded-xl border border-line bg-fg/5 ${
				compact ? "shrink-0 p-1" : "gap-1.5 p-1.5 xl:justify-end"
			}`}
		>
			<ActionButton
				label="Start"
				tone="start"
				icon={<IconPlay />}
				size="sm"
				iconOnly={compact}
				disabled={running || waiting}
				loading={startLoading}
				onClick={() => onAction("start", domain)}
			/>
			<ActionButton
				label="Restart"
				tone="restart"
				icon={<IconRestart />}
				size="sm"
				iconOnly={compact}
				className={extraClass}
				disabled={!running || waiting}
				loading={action === "restart"}
				onClick={() => onAction("restart", domain)}
			/>
			<ActionButton
				label="Rebuild"
				tone="rebuild"
				icon={<IconRebuild />}
				size="sm"
				iconOnly={compact}
				className={extraClass}
				disabled={waiting}
				loading={action === "rebuild"}
				onClick={() => onAction("rebuild", domain)}
			/>
			<ActionButton
				label="Stop"
				tone="stop"
				icon={<IconStop />}
				size="sm"
				iconOnly={compact}
				disabled={!running || waiting}
				loading={stopLoading}
				onClick={() => onAction("stop", domain)}
			/>
			<ActionButton
				label="Delete"
				tone="stop"
				icon={<IconTrash />}
				size="sm"
				iconOnly={compact}
				className={extraClass}
				disabled={waiting}
				loading={action === "delete"}
				onClick={() => onDelete?.(domain)}
			/>
			<MoreActions
				running={running}
				waiting={waiting}
				action={action}
				onRestart={() => onAction("restart", domain)}
				onRebuild={() => onAction("rebuild", domain)}
				onDelete={() => onDelete?.(domain)}
			/>
		</div>
	);
}

function MoreActions({ running, waiting, action, onRestart, onRebuild, onDelete }) {
	const [open, setOpen] = useState(false);
	const root = useRef(null);
	const busy = action === "restart" || action === "rebuild" || action === "delete";

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

	function run(fn) {
		setOpen(false);
		fn?.();
	}

	return (
		<div className="relative md:hidden" ref={root}>
			<button
				type="button"
				title="More actions"
				aria-label="More actions"
				aria-haspopup="menu"
				aria-expanded={open}
				disabled={waiting && !busy}
				onClick={event => {
					event.stopPropagation();
					setOpen(value => !value);
				}}
				className={`inline-flex h-7 w-7 items-center justify-center rounded-lg font-semibold text-fg transition hover:bg-fg/15 disabled:pointer-events-none disabled:opacity-50 ${
					open || busy ? "bg-fg/15" : "bg-fg/10"
				}`}
			>
				{busy ? <Spinner className="h-3.5 w-3.5" /> : <IconMore />}
			</button>
			{open ? (
				<div
					role="menu"
					className="absolute right-0 top-[calc(100%+0.35rem)] z-40 min-w-[11rem] overflow-hidden rounded-xl border border-line bg-panel py-1 shadow-card"
				>
					<MoreItem
						label="Restart"
						icon={<IconRestart />}
						disabled={!running || waiting}
						loading={action === "restart"}
						onClick={() => run(onRestart)}
					/>
					<MoreItem
						label="Rebuild"
						icon={<IconRebuild />}
						disabled={waiting}
						loading={action === "rebuild"}
						onClick={() => run(onRebuild)}
					/>
					<MoreItem
						label="Delete"
						icon={<IconTrash />}
						danger
						disabled={waiting}
						loading={action === "delete"}
						onClick={() => run(onDelete)}
					/>
				</div>
			) : null}
		</div>
	);
}

function MoreItem({ label, icon, disabled, loading, danger = false, onClick }) {
	return (
		<button
			type="button"
			role="menuitem"
			disabled={disabled}
			onClick={event => {
				event.stopPropagation();
				onClick?.();
			}}
			className={`flex w-full items-center gap-2 px-3 py-2 text-left text-[13px] font-semibold disabled:pointer-events-none disabled:opacity-40 ${
				danger ? "text-danger hover:bg-danger/10" : "text-fg hover:bg-fg/10"
			}`}
		>
			{loading ? <Spinner className="h-3.5 w-3.5" /> : icon}
			{label}
		</button>
	);
}

function ServiceRow({
	project,
	services,
	busy,
	pending,
	expect,
	building,
	onLogs,
	onServiceAction,
	logContainer,
	dozzleBase,
}) {
	if (!services.length) return null;

	return (
		<div className="flex flex-wrap gap-1.5">
			{services.map(item => {
				const serviceName = item.service || item.name;
				const containerName = item.name || item.service;
				const busyKey = `svc:${project.domain}:${serviceName}`;
				const serviceExpect = pending[busyKey];
				const serviceWaiting = !!busy?.[busyKey] || !!serviceExpect || !!expect || building;
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
						waiting={serviceWaiting}
						dozzleUrl={item.state === "missing" ? "" : dozzleContainerUrl(containerName, dozzleBase)}
						onLogs={() => onLogs?.(containerName, serviceName)}
						onStart={() => onServiceAction?.("start", project.domain, serviceName)}
						onStop={() => onServiceAction?.("stop", project.domain, serviceName)}
					/>
				);
			})}
		</div>
	);
}
