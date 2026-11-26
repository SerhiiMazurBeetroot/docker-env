"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { useDisplay } from "../display/DisplayProvider";
import { IconChevron, IconPlus } from "../ui/Icons";
import { ProjectSkeleton } from "../ui/Skeleton";
import { groupProjectsByType, typeTone } from "../../lib/projects";
import SiteCard from "./SiteCard";

// Comfortable: one wide, detailed card per row. Grid: small tiles, many per row. Compact: one-line rows.
const GRID = {
	comfortable: "grid-cols-1 gap-4",
	grid: "grid-cols-[repeat(auto-fill,minmax(min(100%,17.5rem),1fr))] gap-3",
	compact: "grid-cols-1 gap-1.5",
};

export default function SiteGrid({
	projects,
	visible,
	error,
	history,
	busy,
	pending = {},
	onAction,
	onLogs,
	onServiceAction,
	onOpen,
	onHosts,
	onDelete,
	onCreate,
	selectedDomain,
	logContainer,
	dozzleBase,
}) {
	const { density, expandAll, groupByType } = useDisplay();
	const [overrides, setOverrides] = useState({});
	// Collapsed type sections, for this visit only.
	const [collapsed, setCollapsed] = useState({});

	useEffect(() => {
		setOverrides({});
	}, [expandAll]);

	function isOpen(domain) {
		return Object.prototype.hasOwnProperty.call(overrides, domain) ? overrides[domain] : expandAll;
	}

	if (error) {
		return <div className="rounded-2xl border border-danger/30 bg-danger/10 px-5 py-4 text-danger">{error}</div>;
	}

	if (projects == null) {
		return <ProjectSkeleton grid={density === "grid"} compact={density === "compact"} />;
	}

	if (projects.length > 0 && visible.length === 0) {
		return (
			<div className="rounded-2xl border border-dashed border-line bg-panel/60 px-6 py-12 text-center text-muted">
				No sites match this filter.
			</div>
		);
	}

	const gridClass = `grid ${GRID[density] || GRID.comfortable}`;

	const renderCard = (project, index) => (
		<SiteCard
			key={project.domain}
			project={project}
			index={projects.indexOf(project) >= 0 ? projects.indexOf(project) : index}
			history={history?.sites?.[project.domain]}
			variant={density}
			action={busy[project.domain]}
			busy={busy}
			pending={pending}
			detailsOpen={isOpen(project.domain)}
			onToggleDetails={() =>
				setOverrides((current) => ({ ...current, [project.domain]: !isOpen(project.domain) }))
			}
			onAction={onAction}
			onLogs={onLogs}
			onServiceAction={onServiceAction}
			onOpen={onOpen}
			onHosts={onHosts}
			onDelete={onDelete}
			selected={selectedDomain === project.domain}
			logContainer={logContainer}
			dozzleBase={dozzleBase}
		/>
	);

	if (groupByType) {
		return (
			<div className="grid gap-6">
				{groupProjectsByType(visible).map((group) => {
					const open = !collapsed[group.type];
					return (
						<section key={group.type} aria-label={`${group.type} sites`}>
							<header className="mb-2.5 flex items-center gap-2.5">
								<button
									type="button"
									onClick={() => setCollapsed((current) => ({ ...current, [group.type]: open }))}
									aria-expanded={open}
									title={open ? `Collapse ${group.type}` : `Expand ${group.type}`}
									className="inline-flex items-center gap-2 rounded-lg py-0.5 pr-1.5 text-left hover:text-fg"
								>
									<IconChevron className={`h-3.5 w-3.5 text-muted transition ${open ? "" : "-rotate-90"}`} />
									<span className={`rounded-md px-2 py-0.5 font-mono text-[12px] font-medium ${typeTone(group.type)}`}>
										{group.type}
									</span>
									<span className="font-mono text-[12px] tabular-nums text-muted">
										{group.items.filter((item) => item.running).length}/{group.items.length} running
									</span>
								</button>
								<span aria-hidden className="h-px flex-1 bg-line" />
								{group.guide ? (
									<Link href={group.guide} className="text-[12px] text-muted hover:text-accent">
										Guide
									</Link>
								) : null}
							</header>
							{open ? <div className={gridClass}>{group.items.map(renderCard)}</div> : null}
						</section>
					);
				})}
				{onCreate ? (
					<button
						type="button"
						onClick={onCreate}
						className="flex h-14 items-center justify-center gap-2 rounded-2xl border border-dashed border-line px-4 text-[13px] font-semibold text-muted transition hover:border-accent/60 hover:text-accent"
					>
						<IconPlus className="h-4 w-4" />
						New site
					</button>
				) : null}
			</div>
		);
	}

	return (
		<div className={gridClass}>
			{visible.map(renderCard)}
			{onCreate && density !== "grid" ? (
				<button
					type="button"
					onClick={onCreate}
					className={`flex items-center justify-center gap-2 border border-dashed border-line px-4 text-[13px] font-semibold text-muted transition hover:border-accent/60 hover:text-accent ${
						density === "compact" ? "h-11 rounded-xl" : "h-14 rounded-2xl"
					}`}
				>
					<IconPlus className="h-4 w-4" />
					{projects.length ? "New site" : "Create your first site"}
				</button>
			) : null}
			{onCreate && density === "grid" ? (
				<button
					type="button"
					onClick={onCreate}
					className="flex min-h-[14rem] flex-col items-center justify-center gap-2 rounded-2xl border border-dashed border-line px-6 text-center text-muted transition hover:border-accent/60 hover:text-accent"
				>
					<span className="grid h-10 w-10 place-items-center rounded-full border border-current">
						<IconPlus className="h-4 w-4" />
					</span>
					<span className="font-display text-base font-semibold text-fg">
						{projects.length ? "New site" : "Create your first site"}
					</span>
					<span className="text-[12px]">WordPress, Bedrock, Next.js, PHP, Node API, Directus and more</span>
				</button>
			) : null}
		</div>
	);
}
