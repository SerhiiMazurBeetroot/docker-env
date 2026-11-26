"use client";

import { useCallback, useEffect, useState } from "react";
import AppShell from "../layout/AppShell";
import { Spinner } from "../ui/Icons";
import DevBadge from "../ui/DevBadge";

// Order and wording of the groups written by updates_check.sh.
const GROUPS = [
	{ id: "images", title: "System images", hint: "docker-compose.yml for nginx, mkcert and dozzle" },
	{ id: "webui", title: "Web UI base", hint: "Base images in the Web UI Dockerfile" },
	{ id: "npm", title: "Web UI packages", hint: "package.json ranges, versions from package-lock.json" },
	{ id: "docker-env", title: "docker-env", hint: "This checkout against the latest GitHub release" },
];

// Literal class strings per tone so Tailwind keeps them.
const TONES = {
	ok: { pill: "bg-ok/12 text-ok", dot: "bg-ok", stripe: "rgb(var(--ok))", text: "text-ok", box: "border-ok/30 bg-ok/[0.05]" },
	accent: {
		pill: "bg-accent/12 text-accent",
		dot: "bg-accent",
		stripe: "rgb(var(--accent))",
		text: "text-accent",
		box: "border-accent/30 bg-accent/[0.05]",
	},
	warn: { pill: "bg-warn/12 text-warn", dot: "bg-warn", stripe: "rgb(var(--warn))", text: "text-warn", box: "border-warn/30 bg-warn/[0.06]" },
	danger: {
		pill: "bg-danger/12 text-danger",
		dot: "bg-danger",
		stripe: "rgb(var(--danger))",
		text: "text-danger",
		box: "border-danger/30 bg-danger/[0.06]",
	},
	muted: { pill: "bg-fg/10 text-muted", dot: "bg-muted", stripe: "rgb(var(--muted) / 0.45)", text: "text-muted", box: "border-line bg-fg/[0.03]" },
};

const STATUS = {
	ok: { label: "up to date", tone: "ok" },
	update: { label: "update available", tone: "accent" },
	major: { label: "new major", tone: "warn" },
	recreate: { label: "recreate container", tone: "warn" },
	rebuild: { label: "rebuild image", tone: "warn" },
	"eol-soon": { label: "end of life soon", tone: "warn" },
	eol: { label: "end of life", tone: "danger" },
	unpinned: { label: "not pinned", tone: "danger" },
	stale: { label: "no recent release", tone: "muted" },
	unknown: { label: "unknown", tone: "muted" },
};

// Statuses with something to do. "stale" and "unknown" are information only.
const ACTIONABLE = new Set(["update", "major", "recreate", "rebuild", "eol-soon", "eol", "unpinned"]);

const KIND = { image: "image", node: "runtime", npm: "npm", release: "release" };

export default function UpdatesPage({ enabled }) {
	const [data, setData] = useState(null);
	const [loaded, setLoaded] = useState(false);
	const [checking, setChecking] = useState(false);
	const [error, setError] = useState("");

	const load = useCallback(async () => {
		try {
			const response = await fetch("/api/updates", { cache: "no-store" });
			const body = await response.json();
			if (!response.ok || !body.ok) {
				setError(body.error || "Could not load the updates check");
				return;
			}
			setData(body.data);
			setChecking(!!body.running);
		} catch (err) {
			setError(err.message || "Could not load the updates check");
		} finally {
			setLoaded(true);
		}
	}, []);

	useEffect(() => {
		if (enabled) load();
	}, [enabled, load]);

	async function checkNow() {
		setChecking(true);
		setError("");
		try {
			const response = await fetch("/api/updates", { method: "POST" });
			const body = await response.json();
			if (body.data) setData(body.data);
			if (!response.ok || !body.ok) setError(body.error || "Updates check failed");
		} catch (err) {
			setError(err.message || "Updates check failed");
		} finally {
			setChecking(false);
		}
	}

	return (
		<AppShell active="updates">
			<main className="w-full max-w-5xl px-4 py-8 sm:px-8">
				<p className="m-0 font-mono text-[11px] uppercase tracking-[0.14em] text-muted">
					docker-env / developer
				</p>
				<div className="mt-1 flex flex-wrap items-end justify-between gap-3">
					<div>
						<h2 className="m-0 flex items-center gap-2.5 font-display text-3xl font-semibold">
							Updates
							<DevBadge className="text-[11px] leading-[18px]" />
						</h2>
						<p className="mt-2 text-sm text-muted">
							What the repo pins, what is running, and what is published. Nothing here changes a pin or pulls an image.
						</p>
					</div>
					{enabled ? (
						<button
							type="button"
							onClick={checkNow}
							disabled={checking}
							className="inline-flex items-center gap-2 rounded-lg bg-accent px-3 py-2 text-sm font-semibold text-white disabled:opacity-60"
						>
							{checking ? <Spinner className="h-4 w-4" /> : null}
							{checking ? "Checking…" : "Check now"}
						</button>
					) : null}
				</div>

				{!enabled ? (
					<Notice>
						This page is a developer tool. Set <code className="font-mono">ENV_MODE=development</code> in <code className="font-mono">.env-core/data/settings.log</code> to use it.
					</Notice>
				) : (
					<>
						<Meta data={data} checking={checking} />
						{error ? <Notice tone="danger">{error}</Notice> : null}
						{data?.errors?.length ? (
							<Notice tone="warn">
								<p className="m-0 font-semibold text-fg">Some lookups failed, so those rows show “unknown”:</p>
								<ul className="mb-0 mt-2 list-disc space-y-1 pl-5">
									{data.errors.map((line) => (
										<li key={line}>{line}</li>
									))}
								</ul>
							</Notice>
						) : null}
						{data && !data.docker ? (
							<Notice tone="warn">Docker was not reachable during the check, so the Running column is empty.</Notice>
						) : null}
						{!loaded ? (
							<p className="mt-8 text-sm text-muted">Loading…</p>
						) : !data ? (
							<Notice>
								No check has run yet. It runs once a day in development mode, or press{" "}
								<span className="font-medium text-fg">Check now</span>.
							</Notice>
						) : (
							GROUPS.map((group) => (
								<Group key={group.id} group={group} items={data.items.filter((item) => item.group === group.id)} />
							))
						)}
					</>
				)}
			</main>
		</AppShell>
	);
}

function Meta({ data, checking }) {
	if (!data) return null;
	const checked = new Date(data.checked);
	const when = Number.isNaN(checked.getTime()) ? data.checked : checked.toLocaleString();
	const { attention = 0, ok = 0, total = 0 } = data.summary || {};
	return (
		<div className="mt-6 flex flex-wrap items-center gap-2 text-sm">
			<Chip tone={attention ? "bg-warn/12 text-warn" : "bg-ok/12 text-ok"}>
				{attention ? `${attention} need${attention === 1 ? "s" : ""} attention` : "everything up to date"}
			</Chip>
			<Chip tone="bg-fg/10 text-muted">
				{ok} of {total} up to date
			</Chip>
			<span className="text-muted">{checking ? "Checking now…" : `Checked ${when}`}</span>
		</div>
	);
}

function Group({ group, items }) {
	if (!items.length) return null;
	const todo = items.filter((item) => ACTIONABLE.has(item.status)).length;
	return (
		<section className="mt-8 overflow-hidden rounded-2xl border border-line bg-panel/90">
			<div className="flex flex-wrap items-center justify-between gap-2 border-b border-line px-4 py-3">
				<div className="min-w-0">
					<p className="m-0 text-[11px] font-semibold uppercase tracking-wider text-fg/90">{group.title}</p>
					<p className="m-0 mt-0.5 text-xs text-muted">{group.hint}</p>
				</div>
				<Chip tone={todo ? TONES.warn.pill : TONES.ok.pill}>{todo ? `${todo} to update` : "all up to date"}</Chip>
			</div>
			<ul className="m-0 list-none divide-y divide-[color:var(--line)] p-0">
				{items.map((item) => (
					<Row key={item.id} item={item} />
				))}
			</ul>
		</section>
	);
}

// What the row is moving from and to. The target is what applying the hint gives.
function versionFlow(item) {
	const current = item.running || item.pinned || "";
	const inSeries = item.latestInSeries || "";
	const newest = item.latestMajor || "";
	let target = "";
	switch (item.status) {
		case "update":
			target = inSeries && inSeries !== current ? inSeries : newest;
			break;
		case "major":
		case "eol":
		case "eol-soon":
			target = newest;
			break;
		case "rebuild":
		case "recreate":
			target = inSeries || item.pinned;
			break;
		default:
			target = "";
	}
	if (target === current) target = "";
	// A newer major beyond the target, shown as a hint (Node 26 LTS while 24 is pinned).
	const beyond = newest && newest !== target && newest !== current && majorOf(newest) > majorOf(target || current) ? newest : "";
	return { current, target, beyond };
}

function majorOf(version) {
	const match = String(version).replace(/^v/, "").match(/^(\d+)/);
	return match ? Number(match[1]) : -1;
}

function Row({ item }) {
	const status = STATUS[item.status] || STATUS.unknown;
	const tone = TONES[status.tone];
	const { current, target, beyond } = versionFlow(item);
	const where = item.file ? `${item.file}${item.line ? `:${item.line}` : ""}` : "";
	const needsWork = ACTIONABLE.has(item.status);
	// Image rows are named "service (repo)"; the pin line below already shows the repo.
	const name = item.kind === "image" ? String(item.name).replace(/\s*\([^)]*\)$/, "") : item.name;
	const pinLabel = item.kind === "npm" ? "range" : "pin";

	return (
		<li className={`px-4 ${needsWork ? "py-4" : "py-3"}`} style={{ boxShadow: `inset 3px 0 0 ${tone.stripe}` }}>
			<div className="grid items-center gap-x-4 gap-y-2 sm:grid-cols-[minmax(0,1.2fr)_minmax(0,1.3fr)_auto]">
				<div className="min-w-0">
					<p className="m-0 flex flex-wrap items-center gap-2">
						<span className="break-words font-semibold text-fg">{name}</span>
						<span className="rounded border border-line px-1.5 py-px font-mono text-[10px] uppercase tracking-wider text-muted">
							{KIND[item.kind] || item.kind}
						</span>
					</p>
					{item.pinned && item.pinned !== current ? (
						<p className="m-0 mt-1 break-words font-mono text-[12px] text-muted">
							<span className="mr-1.5 font-sans text-[11px] uppercase tracking-wider">{pinLabel}</span>
							<Breakable text={item.pinned} />
						</p>
					) : null}
				</div>

				<div className="flex min-w-0 flex-wrap items-center gap-2 font-mono text-[13px]">
					{current ? (
						<span className={`rounded-md px-2 py-0.5 ${target ? tone.pill : "bg-fg/[0.06] text-fg"}`} title="Running now">
							<Breakable text={current} />
						</span>
					) : (
						<span className="text-muted">—</span>
					)}
					{target ? (
						<>
							<span aria-hidden className="text-muted">
								→
							</span>
							<span className={`rounded-md px-2 py-0.5 font-semibold ${TONES.ok.pill}`} title="After the update">
								<Breakable text={target} />
							</span>
						</>
					) : item.status === "ok" ? (
						<span className={`${TONES.ok.text}`} aria-label="up to date">
							✓
						</span>
					) : null}
					{beyond ? <span className="font-sans text-xs text-muted">newest {beyond}</span> : null}
				</div>

				<span className={`inline-flex items-center gap-1.5 justify-self-start rounded-full px-2.5 py-1 text-xs font-semibold sm:justify-self-end ${tone.pill}`}>
					<span className={`h-1.5 w-1.5 rounded-full ${tone.dot}`} />
					{status.label}
				</span>
			</div>

			{needsWork && (item.note || where || item.apply) ? (
				<div className={`mt-3 grid gap-2 rounded-xl border px-3 py-2.5 text-[13px] ${tone.box}`}>
					{item.note ? <p className="m-0 text-fg/90">{item.note}</p> : null}
					{item.apply ? (
						<p className="m-0 text-fg/90">
							<span className={`mr-2 text-[11px] font-semibold uppercase tracking-wider ${tone.text}`}>How</span>
							{item.apply}
						</p>
					) : null}
					{where ? (
						<p className="m-0 text-muted">
							<span className="mr-2 text-[11px] font-semibold uppercase tracking-wider">Edit</span>
							<code className="break-all font-mono text-[12px] text-fg/80">{where}</code>
						</p>
					) : null}
				</div>
			) : item.note ? (
				<p className="m-0 mt-1.5 text-xs text-muted">{item.note}</p>
			) : null}
		</li>
	);
}

// Image refs wrap after "/" and ":" instead of in the middle of a name.
function Breakable({ text }) {
	const parts = String(text).split(/(?<=[/:])/);
	return parts.map((part, index) => (
		<span key={index}>
			{part}
			{index < parts.length - 1 ? <wbr /> : null}
		</span>
	));
}

function Chip({ tone, children }) {
	return <span className={`rounded-full px-2.5 py-1 text-xs font-semibold ${tone}`}>{children}</span>;
}

function Notice({ tone = "", children }) {
	const tones = {
		danger: "border-danger/40 bg-danger/[0.06]",
		warn: "border-warn/40 bg-warn/[0.06]",
	};
	return (
		<div className={`mt-6 rounded-2xl border px-4 py-3 text-sm text-muted ${tones[tone] || "border-line bg-panel/90"}`}>
			{children}
		</div>
	);
}
