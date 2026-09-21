"use client";

import { useEffect, useState } from "react";
import { IconCheck, IconClose, IconCopy, IconExternal, IconTrash, Spinner } from "../ui/Icons";

export default function ProjectDetail({ domain, onClose, onDelete }) {
	const [data, setData] = useState(null);
	const [error, setError] = useState("");
	const [loading, setLoading] = useState(false);

	useEffect(() => {
		if (!domain) return undefined;
		let cancelled = false;
		setLoading(true);
		setError("");
		setData(null);
		fetch(`/api/projects/${encodeURIComponent(domain)}`)
			.then(async (response) => {
				const body = await response.json();
				if (cancelled) return;
				if (!body.ok) {
					setError(body.error || "Could not load project");
					return;
				}
				setData(body);
			})
			.catch((err) => {
				if (!cancelled) setError(err.message || "Could not load project");
			})
			.finally(() => {
				if (!cancelled) setLoading(false);
			});
		return () => {
			cancelled = true;
		};
	}, [domain]);

	useEffect(() => {
		if (!domain) return undefined;
		function onKey(event) {
			if (event.key === "Escape") onClose?.();
		}
		window.addEventListener("keydown", onKey);
		return () => window.removeEventListener("keydown", onKey);
	}, [domain, onClose]);

	if (!domain) return null;

	return (
		<div className="fixed inset-0 z-40 flex justify-end">
			<button type="button" className="absolute inset-0 bg-ink/50" aria-label="Close details" onClick={onClose} />
			<aside className="relative z-10 flex h-full w-full max-w-xl flex-col border-l border-line bg-panel shadow-card">
				<header className="flex items-start justify-between gap-3 border-b border-line px-5 py-4">
					<div className="min-w-0">
						<p className="m-0 text-[10px] font-bold uppercase tracking-wider text-muted">Project</p>
						<h2 className="m-0 truncate text-lg font-extrabold tracking-tight">{domain}</h2>
						{data?.domainFull ? (
							<p className="mt-0.5 truncate font-mono text-xs text-muted">{data.domainFull}</p>
						) : null}
					</div>
					<div className="flex shrink-0 items-center gap-1">
						<button
							type="button"
							onClick={() => onDelete?.(domain)}
							className="rounded-lg p-2 text-danger hover:bg-danger/10"
							title="Delete project"
						>
							<IconTrash />
						</button>
						<button
							type="button"
							onClick={onClose}
							className="rounded-lg p-2 text-muted hover:bg-raised hover:text-fg"
							title="Close"
						>
							<IconClose />
						</button>
					</div>
				</header>
				<div className="min-h-0 flex-1 overflow-y-auto px-5 py-4">
					{loading ? (
						<div className="flex items-center gap-2 text-sm text-muted">
							<Spinner className="h-4 w-4" />
							Loading details…
						</div>
					) : null}
					{error ? <p className="m-0 text-sm text-danger">{error}</p> : null}
					{data ? <DetailBody data={data} /> : null}
				</div>
			</aside>
		</div>
	);
}

function DetailBody({ data }) {
	const last = data.lastAction;
	return (
		<div className="grid gap-5">
			<section>
				<SectionTitle>Last action</SectionTitle>
				{last ? (
					<p className="m-0 text-sm">
						<span className="font-semibold">{last.action}</span>
						<span className={last.ok ? "text-ok" : "text-danger"}> {last.ok ? "ok" : "failed"}</span>
						<span className="text-muted"> · {formatWhen(last.at)}</span>
					</p>
				) : (
					<p className="m-0 text-sm text-muted">No Web UI action recorded yet.</p>
				)}
			</section>

			<section>
				<SectionTitle>Compose file</SectionTitle>
				<PathRow label="Project" path={data.paths?.root} href={data.editor?.root} />
				<PathRow label="Compose" path={data.paths?.composeFile} href={data.editor?.compose} />
				<PathRow label="Env file" path={data.paths?.envFile} href={data.editor?.env} />
				{data.composePreview ? (
					<pre className="mt-3 max-h-56 overflow-auto rounded-xl border border-line bg-raised p-3 font-mono text-[11px] leading-relaxed text-chip">
						{data.composePreview}
					</pre>
				) : (
					<p className="mt-2 text-sm text-muted">No docker-compose.yml found.</p>
				)}
			</section>

			<section>
				<SectionTitle>Ports</SectionTitle>
				{data.ports?.length ? (
					<ul className="m-0 grid list-none gap-1.5 p-0">
						{data.ports.map((item, index) => (
							<li
								key={`${item.service}-${item.published}-${item.target}-${index}`}
								className="flex flex-wrap items-baseline gap-2 rounded-lg border border-line bg-raised px-3 py-2 font-mono text-xs"
							>
								<span className="text-muted">{item.service}</span>
								<span>
									{item.published || "—"}:{item.target || "—"}
								</span>
								<span className="text-muted">{item.protocol}</span>
							</li>
						))}
					</ul>
				) : (
					<p className="m-0 text-sm text-muted">No published ports in compose.</p>
				)}
			</section>

			<section>
				<SectionTitle>Disk / volumes</SectionTitle>
				<p className="mb-2 text-sm">
					Project size{" "}
					<span className="font-semibold">{data.disk?.project || "—"}</span>
				</p>
				{data.volumes?.length ? (
					<ul className="m-0 grid list-none gap-1.5 p-0">
						{data.volumes.map((item, index) => (
							<li
								key={`${item.service}-${item.source}-${item.destination}-${index}`}
								className="rounded-lg border border-line bg-raised px-3 py-2"
							>
								<div className="text-[10px] font-bold uppercase tracking-wider text-muted">
									{item.service} · {item.type}
								</div>
								<div className="mt-0.5 break-all font-mono text-[11px]">
									{item.source || "—"}
									{item.destination ? ` → ${item.destination}` : ""}
								</div>
							</li>
						))}
					</ul>
				) : (
					<p className="m-0 text-sm text-muted">No volumes in compose.</p>
				)}
			</section>

			<section>
				<SectionTitle>Env keys</SectionTitle>
				<p className="mb-2 text-[11px] text-muted">Names only. Secret-looking keys are marked; values are never shown.</p>
				{data.env?.length ? (
					<ul className="m-0 flex list-none flex-wrap gap-1.5 p-0">
						{data.env.map((item) => (
							<li
								key={item.key}
								className="inline-flex items-center gap-1 rounded-lg border border-line bg-raised px-2 py-1 font-mono text-[11px]"
							>
								{item.key}
								{item.secret ? (
									<span className="rounded bg-danger/15 px-1 text-[9px] font-bold uppercase tracking-wide text-danger">
										secret
									</span>
								) : null}
								{!item.set ? <span className="text-[10px] text-muted">empty</span> : null}
							</li>
						))}
					</ul>
				) : (
					<p className="m-0 text-sm text-muted">No env keys found.</p>
				)}
			</section>
		</div>
	);
}

function SectionTitle({ children }) {
	return <h3 className="mb-2 mt-0 text-[10px] font-bold uppercase tracking-wider text-muted">{children}</h3>;
}

function PathRow({ label, path, href }) {
	if (!path) return null;
	return (
		<div className="mb-1.5 flex items-start gap-2 rounded-lg border border-line bg-raised px-3 py-2">
			<div className="min-w-0 flex-1">
				<div className="text-[10px] font-bold uppercase tracking-wider text-muted">{label}</div>
				<div className="break-all font-mono text-[11px]">{path}</div>
			</div>
			<div className="flex shrink-0 items-center gap-0.5">
				{href ? (
					<a
						href={href}
						className="rounded p-1 text-muted hover:bg-accent/15 hover:text-accent"
						title="Open in editor"
					>
						<IconExternal className="h-3.5 w-3.5" />
					</a>
				) : null}
				<CopyButton value={path} />
			</div>
		</div>
	);
}

function CopyButton({ value }) {
	const [copied, setCopied] = useState(false);
	async function copy(event) {
		event.preventDefault();
		try {
			await navigator.clipboard.writeText(value);
			setCopied(true);
			window.setTimeout(() => setCopied(false), 1400);
		} catch (err) {
			setCopied(false);
		}
	}
	return (
		<button type="button" onClick={copy} className="rounded p-1 text-muted hover:bg-accent/15 hover:text-accent" title="Copy path">
			{copied ? <IconCheck className="h-3.5 w-3.5 text-ok" /> : <IconCopy className="h-3.5 w-3.5" />}
		</button>
	);
}

function formatWhen(iso) {
	if (!iso) return "";
	const date = new Date(iso);
	if (Number.isNaN(date.getTime())) return iso;
	return date.toLocaleString();
}
