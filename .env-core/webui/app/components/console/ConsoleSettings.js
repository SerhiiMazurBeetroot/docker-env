"use client";

import { useConsoleSettings } from "./ConsoleSettingsProvider";

function Toggle({ checked, onChange, label }) {
	return (
		<button
			type="button"
			role="switch"
			aria-checked={checked}
			aria-label={label}
			onClick={() => onChange(!checked)}
			className={`relative h-5 w-9 rounded-full transition ${checked ? "bg-accent" : "bg-fg/15"}`}
		>
			<span
				className={`absolute top-0.5 h-4 w-4 rounded-full bg-white transition-[left] ${
					checked ? "left-4" : "left-0.5"
				}`}
			/>
		</button>
	);
}

export default function ConsoleSettings() {
	const { autoOpen, setAutoOpen } = useConsoleSettings();

	return (
		<section className="overflow-hidden rounded-2xl border border-line bg-panel/90">
			<div className="border-b border-line px-4 py-3 text-[11px] font-semibold uppercase tracking-wider text-muted">
				Console
			</div>
			<div className="flex min-h-[3.25rem] items-start justify-between gap-3 px-4 py-3.5 text-sm font-medium">
				<span className="min-w-0 flex-1">
					<span className="inline-flex items-center gap-2">Open on actions</span>
					<span className="mt-0.5 block text-xs font-normal text-muted">
						Show the console when you start, stop, rebuild, create, or run other CLI actions. Opening
						container logs still opens the panel.
					</span>
				</span>
				<span className="flex shrink-0 items-center gap-2">
					<Toggle label="Open console on actions" checked={autoOpen} onChange={setAutoOpen} />
				</span>
			</div>
		</section>
	);
}
