"use client";

import { useDisplay } from "./DisplayProvider";

function LayoutCard({ option, label, selected, onSelect, children }) {
	return (
		<button type="button" aria-pressed={selected} onClick={() => onSelect(option)} className="flex flex-col items-center gap-1.5">
			<span
				className={`flex h-12 w-20 flex-col justify-center gap-1 overflow-hidden rounded-md border border-line p-1.5 transition ${
					selected ? "outline outline-2 outline-offset-2 outline-accent" : ""
				}`}
			>
				{children}
			</span>
			<span className={`text-xs ${selected ? "font-medium text-fg" : "font-normal text-muted"}`}>{label}</span>
		</button>
	);
}

export default function DisplayPicker() {
	const { density, setDensity } = useDisplay();

	return (
		<div className="flex min-h-[3.25rem] items-start justify-between gap-3 border-t border-line py-3.5 text-sm font-medium">
			<span className="min-w-0 flex-1">
				<span className="inline-flex items-center gap-2">Project cards</span>
				<span className="mt-0.5 block text-xs font-normal text-muted">
					Comfortable list, compact rows, or a multi-column grid. All layouts group by project type.
				</span>
			</span>
			<span className="flex shrink-0 items-center gap-2">
				<div className="flex gap-3">
					<LayoutCard
						option="comfortable"
						label="Comfortable"
						selected={density === "comfortable"}
						onSelect={setDensity}
					>
						<span className="h-5 w-full rounded-sm bg-fg/20" />
						<span className="h-5 w-full rounded-sm bg-fg/12" />
					</LayoutCard>
					<LayoutCard option="compact" label="Compact" selected={density === "compact"} onSelect={setDensity}>
						<span className="h-2 w-full rounded-sm bg-fg/20" />
						<span className="h-2 w-full rounded-sm bg-fg/15" />
						<span className="h-2 w-full rounded-sm bg-fg/10" />
					</LayoutCard>
					<LayoutCard option="grid" label="Grid" selected={density === "grid"} onSelect={setDensity}>
						<span className="grid grid-cols-2 gap-1">
							<span className="h-4 rounded-sm bg-fg/20" />
							<span className="h-4 rounded-sm bg-fg/14" />
							<span className="h-4 rounded-sm bg-fg/10" />
							<span className="h-4 rounded-sm bg-fg/16" />
						</span>
					</LayoutCard>
				</div>
			</span>
		</div>
	);
}
