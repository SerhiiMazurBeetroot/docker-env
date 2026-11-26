"use client";

import { useEffect, useMemo, useState } from "react";
import { IconClose, IconPlus } from "../ui/Icons";
import DevBadge from "../ui/DevBadge";
import { normalizeProjectDomain } from "../../../lib/domain";
import { versionsForOption } from "../../../lib/versionChoices";

const TYPE_FIELDS = {
	wordpress: [
		{ key: "PHP_VERSION", label: "PHP version" },
		{ key: "WP_VERSION", label: "WordPress version" },
	],
	bedrock: [
		{ key: "PHP_VERSION", label: "PHP version" },
		{ key: "WP_VERSION", label: "WordPress version" },
	],
	php: [{ key: "PHP_VERSION", label: "PHP version" }],
	nextjs: [
		{ key: "NEXTJS_VERSION", label: "Next.js version" },
		{ key: "NODE_VERSION", label: "Node version" },
	],
	directus: [{ key: "DIRECTUS_VERSION", label: "Directus version" }],
	elasticsearch: [{ key: "ELASTIC_VERSION", label: "Elastic version" }],
	laravel: [
		{ key: "PHP_VERSION", label: "PHP version" },
		{ key: "LARAVEL_VERSION", label: "Laravel version" },
	],
	directus_nextjs: [
		{ key: "DIRECTUS_VERSION", label: "Directus version" },
		{ key: "NODE_VERSION", label: "Node version" },
	],
	wordpress_nextjs: [
		{ key: "PHP_VERSION", label: "PHP version" },
		{ key: "WP_VERSION", label: "WordPress version" },
		{ key: "NODE_VERSION", label: "Node version" },
	],
	nodejs_api: [{ key: "NODE_VERSION", label: "Node version" }],
};

export default function CreateProjectModal({ open, onClose, onCreate, busy = false, existing = [] }) {
	const [types, setTypes] = useState([]);
	const [versions, setVersions] = useState({});
	const [type, setType] = useState("wordpress");
	const [domain, setDomain] = useState("");
	const [options, setOptions] = useState({});
	const [error, setError] = useState("");

	useEffect(() => {
		if (!open) return undefined;
		let cancelled = false;
		fetch("/api/catalog")
			.then((response) => response.json())
			.then((body) => {
				if (cancelled || !body.ok) return;
				setTypes(body.types || []);
				setVersions(body.versions || {});
				if (body.types?.[0]?.id) setType(body.types[0].id);
			})
			.catch(() => {
				if (!cancelled) setError("Could not load project types");
			});
		return () => {
			cancelled = true;
		};
	}, [open]);

	const fields = useMemo(() => TYPE_FIELDS[type] || [], [type]);
	const versionOptions = fields.some((field) => field.key === "WP_VERSION") ? options : {};
	const name = normalizeProjectDomain(domain);
	const host = type === "elasticsearch" ? `dev.${name || "mysite"}.elastic` : `dev.${name || "mysite"}.local`;

	useEffect(() => {
		setOptions({});
	}, [type]);

	if (!open) return null;

	function submit(event) {
		event.preventDefault();
		const name = normalizeProjectDomain(domain);
		if (!name) {
			setError("Domain is required");
			return;
		}
		if (!/^[a-z0-9]([a-z0-9-]{0,251}[a-z0-9])?$/.test(name)) {
			setError("Use letters, numbers, and hyphens");
			return;
		}
		// The CLI refuses a taken name too; catching it here keeps that refusal off the console.
		if (existing.includes(name)) {
			setError(`A site named ${name} already exists`);
			return;
		}
		setError("");
		onCreate?.({ type, domain: name, options });
	}

	return (
		<div className="fixed inset-0 z-50 flex items-center justify-center p-4">
			<button type="button" className="absolute inset-0 bg-ink/60" aria-label="Close" onClick={onClose} />
			<form
				onSubmit={submit}
				className="relative z-10 w-full max-w-md rounded-2xl border border-line bg-panel p-5 shadow-card"
			>
				<div className="mb-4 flex items-start justify-between gap-3">
					<div>
						<h2 className="m-0 text-lg font-extrabold tracking-tight">New project</h2>
						<p className="mt-1 text-xs text-muted">Default uses the current recommended release.</p>
					</div>
					<button type="button" onClick={onClose} className="rounded-lg p-1.5 text-muted hover:bg-raised hover:text-fg">
						<IconClose />
					</button>
				</div>
				<label className="mb-3 block text-sm">
					<span className="mb-1 block text-[10px] font-bold uppercase tracking-wider text-muted">Type</span>
					<select
						value={type}
						onChange={(event) => {
							setType(event.target.value);
							setOptions({});
						}}
						className="h-9 w-full rounded-xl border border-line bg-raised px-3 text-sm outline-none focus:border-accent/50"
					>
						{/* WIP types (tier "wip") are listed only in development mode. */}
						{types.map((item) => (
							<option key={item.id} value={item.id}>
								{item.tier === "wip" ? `${item.title} · dev` : item.title}
							</option>
						))}
					</select>
					{types.find((item) => item.id === type)?.tier === "wip" ? (
						<span className="mt-1.5 flex items-center gap-1.5 text-xs text-muted">
							<DevBadge />
							Work-in-progress type, listed only with ENV_MODE=development.
						</span>
					) : null}
				</label>
				<label className="mb-3 block text-sm">
					<span className="mb-1 block text-[10px] font-bold uppercase tracking-wider text-muted">Domain</span>
					<input
						value={domain}
						onChange={(event) => setDomain(event.target.value)}
						placeholder="mysite"
						className="h-9 w-full rounded-xl border border-line bg-raised px-3 text-sm outline-none focus:border-accent/50"
					/>
					<span className="mt-1 block text-[11px] text-muted">
						Short name only. Host becomes {host}
					</span>
				</label>
				{fields.map((field) => {
					const choices = versionsForOption(versions, field.key, versionOptions);
					return (
						<label key={field.key} className="mb-3 block text-sm">
							<span className="mb-1 block text-[10px] font-bold uppercase tracking-wider text-muted">{field.label}</span>
							<select
								value={choices.includes(options[field.key]) ? options[field.key] : ""}
								onChange={(event) => {
									const value = event.target.value;
									setOptions((current) => {
										const next = { ...current, [field.key]: value };
										if (field.key === "WP_VERSION" && next.PHP_VERSION) {
											const phpChoices = versionsForOption(versions, "PHP_VERSION", next);
											if (!phpChoices.includes(next.PHP_VERSION)) next.PHP_VERSION = "";
										}
										return next;
									});
								}}
								className="h-9 w-full rounded-xl border border-line bg-raised px-3 text-sm outline-none focus:border-accent/50"
							>
								<option value="">Default</option>
								{choices.map((version) => (
									<option key={version} value={version}>
										{version}
									</option>
								))}
							</select>
						</label>
					);
				})}
				{error ? <p className="mb-3 text-sm text-danger">{error}</p> : null}
				<div className="flex justify-end gap-2">
					<button type="button" onClick={onClose} className="rounded-lg px-3 py-1.5 text-sm text-muted hover:text-fg">
						Cancel
					</button>
					<button
						type="submit"
						disabled={busy}
						className="inline-flex items-center gap-1.5 rounded-lg bg-ok px-3 py-1.5 text-sm font-semibold text-[#06281c] disabled:opacity-50"
					>
						<IconPlus />
						{busy ? "Creating…" : "Create"}
					</button>
				</div>
			</form>
		</div>
	);
}
