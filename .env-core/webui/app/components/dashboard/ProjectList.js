import { useEffect, useState } from "react";
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
import { IconChevron, IconPlay, IconRebuild, IconRestart, IconStop, IconTrash } from "../ui/Icons";
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
						<div className="flex flex-wrap gap-1">
							<ResourceGlance resources={project.resources} compact={compact || grid} />
							{urls.length === 0 && !compact ? (
								<span className="text-sm text-muted">No URLs yet</span>
							) : (
								urls.map(item => (
									<UrlChip
										key={`${project.domain}-${item.key}`}
										label={URL_LABELS[item.key] || item.key}
										url={item.url}
										compact={compact || grid}
									/>
								))
							)}
							<HostsStatus
								hosts={project.hosts}
								compact={compact || grid}
								busy={!!busy[`hosts:${project.domain}`]}
								onToggle={action => onHosts?.(action, project.domain)}
							/>
						</div>
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

function ActionRow({ compact = false, running, waiting, action, expect, onAction, onDelete, domain }) {
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
				loading={action === "start" || (waiting && expect === "running" && !action)}
				onClick={() => onAction("start", domain)}
			/>
			<ActionButton
				label="Restart"
				tone="restart"
				icon={<IconRestart />}
				size="sm"
				iconOnly={compact}
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
				loading={action === "stop" || (waiting && expect === "stopped" && action === "stop")}
				onClick={() => onAction("stop", domain)}
			/>
			<ActionButton
				label="Delete"
				tone="stop"
				icon={<IconTrash />}
				size="sm"
				iconOnly={compact}
				disabled={waiting}
				loading={action === "delete"}
				onClick={() => onDelete?.(domain)}
			/>
		</div>
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
