import { useDisplay } from "../display/DisplayProvider";
import { IconGroup } from "../ui/Icons";

// Sits next to "Expand all". Hidden with a single type (nothing to group), unless grouping
// is already on, so it can always be switched off again.
export default function GroupByTypeButton({ available = false }) {
	const { groupByType, setGroupByType } = useDisplay();

	if (!available && !groupByType) return null;

	return (
		<button
			type="button"
			aria-pressed={groupByType}
			onClick={() => setGroupByType(!groupByType)}
			title={groupByType ? "Show all sites in one list" : "Group sites by project type"}
			className={`inline-flex h-9 select-none items-center gap-1.5 rounded-xl border bg-panel px-2.5 text-[12px] font-semibold hover:border-accent/40 hover:text-accent ${
				groupByType ? "border-accent/50 text-accent" : "border-line text-fg"
			}`}
		>
			<IconGroup />
			<span>{groupByType ? "Grouped" : "Group by type"}</span>
		</button>
	);
}
