import { useDisplay } from "../display/DisplayProvider";
import { IconCollapse, IconExpand } from "../ui/Icons";

export default function ExpandAllButton() {
	const { expandAll, setExpandAll } = useDisplay();

	return (
		<button
			type="button"
			onClick={() => setExpandAll(!expandAll)}
			title={expandAll ? "Collapse all services" : "Expand all services"}
			className="min-w-28 inline-flex h-9 select-none items-center gap-1.5 rounded-xl border border-line bg-panel px-2.5 text-[12px] font-semibold text-fg hover:border-accent/40 hover:text-accent"
		>
			{expandAll ? <IconCollapse /> : <IconExpand />}
			<span>{expandAll ? "Collapse all" : "Expand all"}</span>
		</button>
	);
}
