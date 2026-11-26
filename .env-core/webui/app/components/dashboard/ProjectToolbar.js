import BulkMenu from "./BulkMenu";
import ExpandAllButton from "./ExpandAllButton";
import GroupByTypeButton from "./GroupByTypeButton";
import { IconSearch } from "../ui/Icons";
import { typeTone } from "../../lib/projects";

export default function ProjectToolbar({
	filters,
	filter,
	onFilter,
	typeCounts = [],
	activeTypes = [],
	onToggleType,
	onClearTypes,
	query,
	onQuery,
	loading,
	projects,
	types = [],
	busy = "",
	onBulk,
}) {
	return (
		<div className="mb-4 flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
			<div className="flex flex-wrap items-center gap-2">
				{filters.map((item) => (
					<button
						key={item.id}
						type="button"
						onClick={() => onFilter(item.id)}
						className={`rounded-full px-3 py-1.5 text-sm font-medium transition ${
							filter === item.id
								? "bg-fg text-ink"
								: "bg-fg/5 text-muted hover:bg-fg/10 hover:text-fg"
						}`}
					>
						{item.label}
						<span className="ml-1.5 opacity-70">{loading ? "…" : item.count}</span>
					</button>
				))}
				{/* Type chips: same colours as the card badges. Hidden with a single type, where
				    they could only show everything or nothing. None selected = every type. */}
				{typeCounts.length > 1 ? (
					<>
						<span aria-hidden className="mx-1 hidden h-5 w-px bg-line sm:block" />
						<div role="group" aria-label="Filter by type" className="flex flex-wrap items-center gap-1.5">
							{typeCounts.map(({ type, count }) => {
								const on = activeTypes.includes(type);
								const dimmed = activeTypes.length > 0 && !on;
								return (
									<button
										key={type}
										type="button"
										aria-pressed={on}
										onClick={() => onToggleType?.(type)}
										title={on ? `Stop filtering by ${type}` : `Show ${type} sites`}
										className={`rounded-full px-2.5 py-1 font-mono text-[12px] font-medium transition ${typeTone(type)} ${
											on ? "ring-1 ring-current" : ""
										} ${dimmed ? "opacity-50 hover:opacity-100" : "hover:brightness-125"}`}
									>
										{type}
										<span className="ml-1.5 opacity-70">{count}</span>
									</button>
								);
							})}
							{activeTypes.length ? (
								<button
									type="button"
									onClick={onClearTypes}
									className="px-1.5 text-xs font-medium text-muted hover:text-fg"
								>
									Clear
								</button>
							) : null}
						</div>
					</>
				) : null}
			</div>
			<div className="flex w-full items-center gap-2 lg:ml-auto lg:w-auto">
				<label className="relative block min-w-0 flex-1 lg:w-72">
					<span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2">
						<IconSearch />
					</span>
					<input
						value={query}
						onChange={(event) => onQuery(event.target.value)}
						placeholder="Search domain, type…"
						className="h-9 w-full rounded-xl border border-line bg-panel pl-10 pr-3 text-sm text-fg outline-none placeholder:text-muted/70 focus:border-accent/50"
					/>
				</label>
				<BulkMenu
					projects={projects}
					types={types}
					loading={loading}
					busy={busy}
					onBulk={onBulk}
				/>
				<GroupByTypeButton available={typeCounts.length > 1} />
				<ExpandAllButton />
			</div>
		</div>
	);
}
