"use client";

import Link from "next/link";
import { useSnapshot } from "../snapshot/SnapshotProvider";

const NAV = [
	{ id: "sites", label: "Sites", href: "/", icon: IconGlobe },
	{ id: "system", label: "System", href: "/?view=system", icon: IconServer },
	{ id: "activity", label: "Activity", href: "/?view=activity", icon: IconPulse },
	{ id: "docs", label: "Docs", href: "/docs", icon: IconBook },
	{ id: "settings", label: "Settings", href: "/settings", icon: IconGear },
];

/*
 * Page frame: sidebar on wide screens, a top bar on phones.
 * `active` names the current section; `badges` adds a small count next to a nav item.
 */
export default function AppShell({ active = "sites", badges = {}, children }) {
	const { projects, system } = useSnapshot();
	const running = projects ? projects.filter((item) => item.running).length : null;
	const counts = { sites: running, ...badges };

	return (
		<div className="flex min-h-screen flex-col md:flex-row">
			<aside className="sticky top-0 z-40 hidden h-screen w-56 shrink-0 flex-col gap-1 border-r border-line bg-ink/70 px-3 py-5 backdrop-blur-xl md:flex">
				<Brand />
				<nav className="mt-5 flex flex-col gap-1" aria-label="Main">
					{NAV.map((item) => (
						<NavItem key={item.id} item={item} active={active === item.id} count={counts[item.id]} />
					))}
				</nav>
				<SystemLights system={system} />
			</aside>

			<header className="sticky top-0 z-40 border-b border-line bg-ink/85 px-4 pb-2 pt-[max(0.75rem,env(safe-area-inset-top))] backdrop-blur-xl md:hidden">
				<Brand />
				<nav className="-mx-1 mt-2 flex gap-1 overflow-x-auto pb-1" aria-label="Main">
					{NAV.map((item) => (
						<NavItem key={item.id} item={item} active={active === item.id} count={counts[item.id]} compact />
					))}
				</nav>
			</header>

			<div className="flex min-w-0 flex-1 flex-col">{children}</div>
		</div>
	);
}

function Brand() {
	return (
		<Link href="/" className="flex items-center gap-2.5 px-2 text-fg">
			<span className="grid h-8 w-8 place-items-center rounded-lg border border-accent/70 font-mono text-[12px] font-medium text-accent shadow-[0_0_14px_-2px_rgb(var(--accent)/0.55),inset_0_0_8px_rgb(var(--accent)/0.2)]">
				de
			</span>
			<span className="font-display text-[17px] font-semibold tracking-wide">docker-env</span>
		</Link>
	);
}

function NavItem({ item, active, count, compact = false }) {
	const Icon = item.icon;
	return (
		<Link
			href={item.href}
			aria-current={active ? "page" : undefined}
			className={`flex shrink-0 items-center gap-2.5 rounded-lg border px-2.5 text-sm transition ${
				compact ? "py-1.5" : "py-2"
			} ${
				active
					? "border-accent/40 bg-accent/[0.07] font-semibold text-fg shadow-[0_0_16px_-6px_rgb(var(--accent)/0.6)]"
					: "border-transparent text-muted hover:bg-fg/5 hover:text-fg"
			}`}
		>
			<Icon className="h-[17px] w-[17px] shrink-0" />
			{item.label}
			{count ? <span className="ml-auto pl-2 font-mono text-[11px] text-accent">{count}</span> : null}
		</Link>
	);
}

function SystemLights({ system = [] }) {
	if (!system.length) return null;
	return (
		<Link
			href="/?view=system"
			className="mt-auto grid gap-2 border-t border-line px-2.5 pt-4 text-xs text-muted hover:text-fg"
			title="System services"
		>
			{system.map((service) => (
				<span key={service.id || service.container} className="flex items-center gap-2">
					<span className={`led ${service.running ? "led-on bg-ok" : "bg-danger"}`} />
					{service.name}
				</span>
			))}
		</Link>
	);
}

function IconGlobe({ className }) {
	return (
		<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className} aria-hidden="true">
			<circle cx="12" cy="12" r="9" />
			<path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18" />
		</svg>
	);
}

function IconServer({ className }) {
	return (
		<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className} aria-hidden="true">
			<rect x="3" y="4" width="18" height="7" rx="2" />
			<rect x="3" y="13" width="18" height="7" rx="2" />
			<path d="M7 7.5h.01M7 16.5h.01" />
		</svg>
	);
}

function IconPulse({ className }) {
	return (
		<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className} aria-hidden="true">
			<path d="M3 12h4l3 8 4-16 3 8h4" />
		</svg>
	);
}

function IconBook({ className }) {
	return (
		<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className} aria-hidden="true">
			<path d="M4 5a2 2 0 0 1 2-2h12v16H6a2 2 0 0 0-2 2z" />
			<path d="M4 19V5" />
		</svg>
	);
}

function IconGear({ className }) {
	return (
		<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className={className} aria-hidden="true">
			<circle cx="12" cy="12" r="3" />
			<path d="M12 2v3M12 19v3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M2 12h3M19 12h3M4.9 19.1L7 17M17 7l2.1-2.1" />
		</svg>
	);
}
