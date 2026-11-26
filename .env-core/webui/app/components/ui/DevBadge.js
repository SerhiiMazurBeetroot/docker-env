/*
 * Marks a developer-only feature: something listed only while ENV_MODE=development
 * (WIP features in sh/core/wip_features.ids, WIP project types, developer docs).
 * Regular users never see these items, so the badge only ever shows to developers.
 */
export const DEV_ONLY_TITLE = "Developer only: visible because ENV_MODE=development";

export default function DevBadge({ className = "" }) {
	return (
		<span
			title={DEV_ONLY_TITLE}
			className={`inline-flex shrink-0 items-center rounded border border-warn/40 bg-warn/10 px-1 font-mono text-[9px] font-bold uppercase leading-[14px] tracking-wider text-warn ${className}`}
		>
			dev
		</span>
	);
}
