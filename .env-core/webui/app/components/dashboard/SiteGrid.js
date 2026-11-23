"use client";

import { useEffect, useState } from "react";
import { useDisplay } from "../display/DisplayProvider";
import { IconPlus } from "../ui/Icons";
import { ProjectSkeleton } from "../ui/Skeleton";
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
	const { density, expandAll } = useDisplay();
	const [overrides, setOverrides] = useState({});

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

	return (
		<div className={`grid ${GRID[density] || GRID.comfortable}`}>
			{visible.map((project, index) => (
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
			))}
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
