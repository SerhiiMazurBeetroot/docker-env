"use client";

import { useState } from "react";
import { IconCheck, IconCopy, IconExternal } from "./Icons";

export default function UrlChip({ label, url, compact = false }) {
	const [copied, setCopied] = useState(false);

	if (!url) return null;

	async function copyUrl(event) {
		event.preventDefault();
		event.stopPropagation();
		try {
			await navigator.clipboard.writeText(url);
			setCopied(true);
			window.setTimeout(() => setCopied(false), 1400);
		} catch (err) {
			setCopied(false);
		}
	}

	return (
		<span
			className={`inline-flex max-w-full items-center gap-1 rounded-lg border border-line bg-raised text-chip ${
				compact ? "pl-2 pr-0.5 py-0.5" : "pl-2.5 pr-0.5 py-1"
			}`}
		>
			<a
				href={url}
				target="_blank"
				rel="noreferrer"
				title={`Open ${url}`}
				className="inline-flex min-w-0 items-center gap-1.5 hover:text-accent"
			>
				<span className="text-[10px] font-bold uppercase tracking-wider text-muted">{label}</span>
				<span className="truncate font-mono text-[11px]">
					{compact ? url.replace(/^https?:\/\//, "") : url}
				</span>
				<IconExternal className="h-3 w-3 shrink-0 text-muted" />
			</a>
			<button
				type="button"
				onClick={copyUrl}
				title={copied ? "Copied" : `Copy ${url}`}
				className="rounded p-1 text-muted hover:bg-accent/15 hover:text-accent"
			>
				{copied ? <IconCheck className="h-3 w-3 text-ok" /> : <IconCopy className="h-3 w-3" />}
			</button>
		</span>
	);
}
