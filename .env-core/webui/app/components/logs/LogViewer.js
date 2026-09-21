"use client";

import { useEffect, useRef } from "react";
import { formatLogClock, formatLogDate } from "../../../lib/logParse";
import { useLogSettings } from "./LogSettingsProvider";

const FONT = {
	small: "text-[11px] leading-[1.45]",
	medium: "text-[12px] leading-[1.5]",
	large: "text-[13px] leading-[1.55]",
};

function LevelMark({ level, rail = false }) {
	if (rail) {
		return <span data-level={level} className="block h-full w-[3px] rounded-full" />;
	}
	return <span data-level={level} className="block size-[0.45em] min-h-1 min-w-1 rounded-full" />;
}

function LogFields({ fields }) {
	if (!fields?.length) return null;
	return (
		<ul className="m-0 inline-flex list-none flex-wrap gap-x-4 gap-y-0.5 p-0">
			{fields.map((item) => (
				<li key={item.key} className="font-mono">
					<span className="text-muted">{item.key}=</span>
					<span className="text-fg">{item.value}</span>
				</li>
			))}
		</ul>
	);
}

function LogEntry({ entry, settings }) {
	const date = entry.ts ? new Date(entry.ts) : null;
	const valid = date && !Number.isNaN(date.getTime());
	const lines = String(entry.message || "").split("\n");
	const multi = lines.length > 1;
	const highlight = settings.highlightErrors && entry.level === "error";

	return (
		<li
			data-log-level={entry.level}
			className={`group/entry ${highlight ? "bg-danger/10" : ""} ${settings.compact ? "py-0" : "py-0.5"}`}
		>
			<div className={`relative flex w-full items-start gap-x-2 ${settings.compact ? "items-stretch" : ""}`}>
				{settings.timestamps ? (
					<div className="shrink-0 select-none whitespace-nowrap pt-px font-mono text-muted tabular-nums group-hover/entry:text-fg/80">
						<div className="inline-flex gap-2">
							{valid ? <time className="max-md:hidden">{formatLogDate(date, settings.dateFormat)}</time> : null}
							{valid ? <time>{formatLogClock(date, settings.timeFormat)}</time> : <span>—</span>}
						</div>
					</div>
				) : null}

				{multi ? (
					<div className="flex min-w-0 flex-1 flex-col">
						{lines.map((line, index) => (
							<div key={`${entry.ts}-${index}`} className="flex items-start gap-x-2">
								<div
									className={`flex w-2.5 flex-none justify-center ${index === 0 ? "h-[1.55em] items-center" : "mt-1.5"}`}
								>
									<LevelMark level={entry.level} rail />
								</div>
								<div
									className={`min-w-0 flex-1 ${settings.wrap ? "whitespace-pre-wrap break-words" : "whitespace-pre"}`}
								>
									{line}
								</div>
							</div>
						))}
					</div>
				) : (
					<>
						<div className="flex h-[1.55em] w-2.5 flex-none items-center justify-center">
							<LevelMark level={entry.level} />
						</div>
						<div
							className={`min-w-0 flex-1 ${settings.wrap ? "whitespace-pre-wrap break-words" : "whitespace-pre"}`}
						>
							{entry.fields?.length ? <LogFields fields={entry.fields} /> : entry.message}
						</div>
					</>
				)}
			</div>
		</li>
	);
}

export default function LogViewer({ entries, follow = false, className = "" }) {
	const { settings } = useLogSettings();
	const scroller = useRef(null);

	useEffect(() => {
		if (!follow || !scroller.current) return;
		scroller.current.scrollTop = scroller.current.scrollHeight;
	}, [entries, follow]);

	return (
		<ul
			ref={scroller}
			data-logs=""
			className={`m-0 list-none overflow-auto p-0 font-mono ${FONT[settings.fontSize] || FONT.medium} ${className}`}
		>
			{(entries || []).map((entry, index) => (
				<LogEntry key={`${entry.ts || "row"}-${index}`} entry={entry} settings={settings} />
			))}
		</ul>
	);
}
