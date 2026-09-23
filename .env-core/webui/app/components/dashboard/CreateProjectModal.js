"use client";

import { useEffect, useMemo, useState } from "react";
import { IconClose, IconPlus } from "../ui/Icons";

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
	wpnextjs: [
		{ key: "PHP_VERSION", label: "PHP version" },
		{ key: "WP_VERSION", label: "WordPress version" },
		{ key: "NODE_VERSION", label: "Node version" },
	],
	nodejs: [{ key: "NODE_VERSION", label: "Node version" }],
};

export default function CreateProjectModal({ open, onClose, onCreate, busy = false }) {
	const [types, setTypes] = useState([]);
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

	useEffect(() => {
		setOptions({});
	}, [type]);

	if (!open) return null;

	function submit(event) {
		event.preventDefault();
		const name = domain.trim().toLowerCase().replace(/_/g, "-").split(".")[0];
		if (!name) {
			setError("Domain is required");
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
						<p className="mt-1 text-xs text-muted">Wraps the CLI create flow. Leave versions empty for defaults.</p>
					</div>
					<button type="button" onClick={onClose} className="rounded-lg p-1.5 text-muted hover:bg-raised hover:text-fg">
						<IconClose />
					</button>
				</div>
				<label className="mb-3 block text-sm">
					<span className="mb-1 block text-[10px] font-bold uppercase tracking-wider text-muted">Type</span>
					<select
						value={type}
						onChange={(event) => setType(event.target.value)}
						className="h-9 w-full rounded-xl border border-line bg-raised px-3 text-sm outline-none focus:border-accent/50"
					>
						{types.map((item) => (
							<option key={item.id} value={item.id}>
								{item.title}
							</option>
						))}
					</select>
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
						Short name only. Host becomes {type === "elasticsearch" ? `dev.${domain || "mysite"}.elastic` : `dev.${domain || "mysite"}.local`}
					</span>
				</label>
				{fields.map((field) => (
					<label key={field.key} className="mb-3 block text-sm">
						<span className="mb-1 block text-[10px] font-bold uppercase tracking-wider text-muted">{field.label}</span>
						<input
							value={options[field.key] || ""}
							onChange={(event) => setOptions((current) => ({ ...current, [field.key]: event.target.value }))}
							placeholder="default"
							className="h-9 w-full rounded-xl border border-line bg-raised px-3 font-mono text-sm outline-none focus:border-accent/50"
						/>
					</label>
				))}
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
