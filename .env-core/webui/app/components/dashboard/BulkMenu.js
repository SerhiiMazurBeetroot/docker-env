"use client";

import { useEffect, useRef, useState } from "react";
import { bulkTargets } from "../../lib/projects";
import ActionButton from "../ui/ActionButton";
import { IconChevron, IconPlay, IconStop } from "../ui/Icons";

export default function BulkMenu({ projects, types = [], loading = false, busy = "", onBulk, align = "right" }) {
	const [open, setOpen] = useState(false);
	const [type, setType] = useState(types[0] || "");
	const root = useRef(null);
	const stopRunningCount = bulkTargets(projects, "stop", "running").length;
	const startStoppedCount = bulkTargets(projects, "start", "stopped").length;
	const typeStartCount = type ? bulkTargets(projects, "start", type).length : 0;
	const typeStopCount = type ? bulkTargets(projects, "stop", type).length : 0;
	const locked = !!busy || loading;

	useEffect(() => {
		if (!types.length) {
			setType("");
			return;
		}
		if (!types.includes(type)) setType(types[0]);
	}, [types, type]);

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

	function runBulk(action, scope) {
		setOpen(false);
		onBulk?.(action, scope);
	}

	return (
		<div className="relative" ref={root}>
			<button
				type="button"
				aria-haspopup="menu"
				aria-expanded={open}
				disabled={loading}
				onClick={() => setOpen((value) => !value)}
				className={`inline-flex h-9 items-center gap-1.5 rounded-xl border px-3 text-sm font-semibold transition ${
					open || busy
						? "border-accent/40 bg-panel text-fg"
						: "border-line bg-panel text-fg hover:border-accent/40 hover:text-accent"
				} disabled:pointer-events-none disabled:opacity-50`}
			>
				Bulk
				{!loading && stopRunningCount > 0 ? (
					<span className="rounded-md bg-danger/15 px-1.5 text-[11px] font-semibold text-danger">{stopRunningCount}</span>
				) : !loading && startStoppedCount > 0 ? (
					<span className="rounded-md bg-ok/15 px-1.5 text-[11px] font-semibold text-ok">{startStoppedCount}</span>
				) : null}
				<IconChevron className={`h-3 w-3 text-muted transition ${open ? "rotate-180" : ""}`} />
			</button>
			{open ? (
				<div
					role="menu"
					className={`absolute top-[calc(100%+0.4rem)] z-30 w-[19rem] space-y-3 rounded-xl border border-line bg-panel p-3 shadow-card ${
						align === "left" ? "left-0" : "right-0"
					}`}
				>
					<BulkGroup
						label="All projects"
						hint={`${startStoppedCount} stopped · ${stopRunningCount} running`}
					>
						<ActionButton
							label="Start stopped"
							tone="start"
							icon={<IconPlay />}
							size="sm"
							disabled={locked || startStoppedCount === 0}
							loading={busy === "start stopped"}
							onClick={() => runBulk("start", "stopped")}
						/>
						<ActionButton
							label="Stop running"
							tone="stop"
							icon={<IconStop />}
							size="sm"
							disabled={locked || stopRunningCount === 0}
							loading={busy === "stop running"}
							onClick={() => runBulk("stop", "running")}
						/>
					</BulkGroup>
					<BulkGroup
						label="By type"
						hint={type ? `${typeStartCount} stopped · ${typeStopCount} running` : "No types yet"}
						aside={
							types.length ? (
								<select
									value={type}
									onChange={(event) => setType(event.target.value)}
									disabled={locked}
									className="h-6 max-w-[8.5rem] rounded-md border border-line bg-raised px-1.5 text-[11px] font-semibold text-fg outline-none focus:border-accent/50"
									title="Project type"
								>
									{types.map((item) => (
										<option key={item} value={item}>
											{item}
										</option>
									))}
								</select>
							) : null
						}
					>
						<ActionButton
							label="Start"
							tone="start"
							icon={<IconPlay />}
							size="sm"
							disabled={locked || !type || typeStartCount === 0}
							loading={busy === `start ${type}`}
							onClick={() => runBulk("start", type)}
						/>
						<ActionButton
							label="Stop"
							tone="stop"
							icon={<IconStop />}
							size="sm"
							disabled={locked || !type || typeStopCount === 0}
							loading={busy === `stop ${type}`}
							onClick={() => runBulk("stop", type)}
						/>
					</BulkGroup>
				</div>
			) : null}
		</div>
	);
}

function BulkGroup({ label, hint, aside, children }) {
	return (
		<div>
			<div className="mb-1.5 flex items-center justify-between gap-2">
				<div className="min-w-0">
					<div className="text-[10px] font-bold uppercase tracking-wider text-muted">{label}</div>
					<div className="truncate text-[11px] text-muted">{hint}</div>
				</div>
				{aside}
			</div>
			<div className="flex flex-wrap items-center gap-1 rounded-lg border border-line bg-fg/5 p-1">{children}</div>
		</div>
	);
}
