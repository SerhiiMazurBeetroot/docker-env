"use client";

import { useTheme } from "./ThemeProvider";

function PreviewLines({ tone }) {
	const bar = tone === "dark" ? "bg-white/25" : "bg-slate-400/50";
	const accent = tone === "dark" ? "bg-sky-300" : "bg-indigo-500";
	return (
		<span className="flex flex-1 flex-col gap-1 p-2">
			<span className={`h-1 w-3/4 rounded-full ${bar}`} />
			<span className={`h-1 w-1/2 rounded-full ${accent}`} />
			<span className={`h-1 w-full rounded-full ${bar}`} />
		</span>
	);
}

function ThemeCard({ option, label, selected, onSelect, children }) {
	return (
		<button
			type="button"
			aria-pressed={selected}
			onClick={() => onSelect(option)}
			className="flex flex-col items-center gap-1.5"
		>
			<span
				className={`flex h-12 w-20 overflow-hidden rounded-md border border-line transition ${
					selected ? "outline outline-2 outline-offset-2 outline-accent" : ""
				}`}
			>
				{children}
			</span>
			<span className={`text-xs ${selected ? "font-medium text-fg" : "font-normal text-muted"}`}>
				{label}
			</span>
		</button>
	);
}

export default function ThemePicker() {
	const { preference, setPreference } = useTheme();

	return (
		<div className="flex min-h-[3.25rem] items-start justify-between gap-3 py-3.5 text-sm font-medium">
			<span className="min-w-0 flex-1">
				<span className="inline-flex items-center gap-2">Theme</span>
			</span>
			<span className="flex shrink-0 items-center gap-2">
				<div className="flex gap-3">
					<ThemeCard option="light" label="Light" selected={preference === "light"} onSelect={setPreference}>
						<span className="flex flex-1 bg-[#f7f8fb]">
							<PreviewLines tone="light" />
						</span>
					</ThemeCard>
					<ThemeCard option="dark" label="Dark" selected={preference === "dark"} onSelect={setPreference}>
						<span className="flex flex-1 bg-[#10151f]">
							<PreviewLines tone="dark" />
						</span>
					</ThemeCard>
					<ThemeCard option="auto" label="Auto" selected={preference === "auto"} onSelect={setPreference}>
						<span className="flex flex-1 bg-[#f7f8fb]">
							<PreviewLines tone="light" />
						</span>
						<span className="flex flex-1 bg-[#10151f]">
							<PreviewLines tone="dark" />
						</span>
					</ThemeCard>
				</div>
			</span>
		</div>
	);
}
