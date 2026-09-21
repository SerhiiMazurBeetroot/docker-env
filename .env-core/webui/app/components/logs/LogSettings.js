"use client";

import {
	LOG_DATE_FORMATS,
	LOG_FONT_SIZES,
	LOG_TIME_FORMATS,
	PREVIEW_LOG_ENTRIES,
} from "../../lib/logSettings";
import { useLogSettings } from "./LogSettingsProvider";
import LogViewer from "./LogViewer";

function Row({ label, hint, children }) {
	return (
		<div className="flex min-h-[3.25rem] items-start justify-between gap-3 border-t border-line px-4 py-3.5 text-sm font-medium first:border-t-0">
			<span className="min-w-0 flex-1">
				<span className="inline-flex items-center gap-2">{label}</span>
				{hint ? <span className="mt-0.5 block text-xs font-normal text-muted">{hint}</span> : null}
			</span>
			<span className="flex shrink-0 items-center gap-2">{children}</span>
		</div>
	);
}

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

function Segment({ value, current, onPick, children }) {
	const selected = value === current;
	return (
		<button
			type="button"
			onClick={() => onPick(value)}
			className={`px-2.5 py-1 text-xs font-semibold first:rounded-l-lg last:rounded-r-lg ${
				selected ? "bg-fg/10 text-fg" : "text-muted hover:text-fg"
			}`}
		>
			{children}
		</button>
	);
}

function NativeSelect({ value, onChange, options }) {
	return (
		<select
			value={value}
			onChange={(event) => onChange(event.target.value)}
			className="h-8 rounded-lg border border-line bg-raised px-2 text-xs font-semibold text-fg"
		>
			{options.map((item) => (
				<option key={item.id} value={item.id}>
					{item.label}
				</option>
			))}
		</select>
	);
}

export default function LogSettings() {
	const { settings, setSettings } = useLogSettings();
	const patch = (partial) => setSettings({ ...settings, ...partial });

	return (
		<section id="logs" className="scroll-mt-4">
			<div className="overflow-hidden rounded-2xl border border-line bg-panel/90">
				<div className="border-b border-line px-4 py-3 text-[11px] font-semibold uppercase tracking-wider text-muted">
					Logs
				</div>
				<div className="px-2 pt-3 pb-1">
					<LogViewer entries={PREVIEW_LOG_ENTRIES} className="max-h-72 rounded-xl bg-fg/5 px-3 py-2" />
				</div>
				<Row label="Font size">
					<span className="inline-flex overflow-hidden rounded-lg border border-line">
						{LOG_FONT_SIZES.map((size) => (
							<Segment
								key={size}
								value={size}
								current={settings.fontSize}
								onPick={(fontSize) => patch({ fontSize })}
							>
								{size[0].toUpperCase() + size.slice(1)}
							</Segment>
						))}
					</span>
				</Row>
				<Row label="Compact mode" hint="Tighter spacing so more lines fit on screen.">
					<Toggle
						label="Compact mode"
						checked={settings.compact}
						onChange={(compact) => patch({ compact })}
					/>
				</Row>
				<Row label="Show timestamps">
					<Toggle
						label="Show timestamps"
						checked={settings.timestamps}
						onChange={(timestamps) => patch({ timestamps })}
					/>
				</Row>
				<Row label="Soft wrap">
					<Toggle label="Soft wrap" checked={settings.wrap} onChange={(wrap) => patch({ wrap })} />
				</Row>
				<Row label="Highlight error rows" hint="The colored level marker is always shown.">
					<Toggle
						label="Highlight error rows"
						checked={settings.highlightErrors}
						onChange={(highlightErrors) => patch({ highlightErrors })}
					/>
				</Row>
				<Row label="Date and time">
					<NativeSelect
						value={settings.dateFormat}
						onChange={(dateFormat) => patch({ dateFormat })}
						options={LOG_DATE_FORMATS}
					/>
					<NativeSelect
						value={settings.timeFormat}
						onChange={(timeFormat) => patch({ timeFormat })}
						options={LOG_TIME_FORMATS}
					/>
				</Row>
			</div>
		</section>
	);
}
