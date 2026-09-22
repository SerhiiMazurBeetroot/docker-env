import { Spinner } from "./Icons";

const TONES = {
	start: "bg-ok text-[#06281c] hover:brightness-110",
	restart: "bg-fg/10 text-fg hover:bg-fg/15",
	rebuild: "bg-warn/90 text-[#3b2704] hover:brightness-110",
	stop: "bg-danger/90 text-[#3b0714] hover:brightness-110",
};

export default function ActionButton({
	label,
	icon,
	tone,
	disabled,
	loading,
	onClick,
	size = "md",
	iconOnly = false,
	className = "",
}) {
	const sizing = iconOnly
		? "h-7 w-7 justify-center px-0"
		: size === "sm"
			? "h-7 px-2 text-[12px]"
			: "h-8 px-2.5 text-[13px]";

	return (
		<button
			type="button"
			title={label}
			aria-label={label}
			disabled={disabled}
			onClick={onClick}
			className={`inline-flex items-center gap-1.5 rounded-lg font-semibold transition disabled:pointer-events-none disabled:bg-white/[0.2] disabled:text-var(--btn-start-text-disabled) disabled:bg-var(--btn-start-bg-disabled) disabled:hover:brightness-100 ${sizing} ${TONES[tone]} ${className}`}
		>
			{loading ? <Spinner className="h-3.5 w-3.5" /> : icon}
			{iconOnly ? null : label}
		</button>
	);
}
