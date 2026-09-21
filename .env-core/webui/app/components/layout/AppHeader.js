"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import ActionButton from "../ui/ActionButton";
import { IconHome, IconPlus, IconSettings, Spinner } from "../ui/Icons";

export default function AppHeader({
	stats,
	loading,
	subtitle = "Local container console",
	createBusy = false,
	onCreate,
}) {
	const pathname = usePathname();
	const onSettings = pathname === "/settings" || pathname?.startsWith("/settings/");
	const value = (n) => (loading ? "…" : n);
	const showCreate = typeof onCreate === "function";

	return (
		<header className="sticky top-0 z-40 shrink-0 border-b border-line bg-ink/80 backdrop-blur-xl">
			<div className="grid grid-cols-[1fr_auto_1fr] items-center gap-4 px-6 py-3">
				<Link href="/" className="flex min-w-0 items-center gap-3 text-fg">
					<div className="relative h-9 w-9 shrink-0 rounded-xl bg-raised shadow-glow">
						<span className="absolute bottom-1.5 left-1.5 h-3 w-6 rounded-[5px] bg-accent" />
						<span className="absolute top-1.5 left-2.5 h-3 w-4 rounded-[5px] bg-ok" />
					</div>
					<div className="min-w-0">
						<h1 className="m-0 text-[16px] font-extrabold tracking-tight">docker-env</h1>
						<p className="m-0 inline-flex items-center gap-1.5 text-xs text-muted">
							{loading ? <Spinner className="h-3 w-3" /> : null}
							{loading ? "Loading projects…" : subtitle}
						</p>
					</div>
				</Link>

				{showCreate ? (
					<ActionButton
						label="Create"
						tone="start"
						icon={<IconPlus />}
						size="sm"
						disabled={loading || createBusy}
						onClick={() => onCreate?.()}
					/>
				) : (
					<div />
				)}

				<div className="flex items-center justify-end gap-5 text-sm">
					{stats ? (
						<>
							<Stat label="Projects" value={value(stats.total)} />
							<Stat label="Running" value={value(stats.running)} tone="text-ok" />
							<Stat label="Building" value={value(stats.building)} tone="text-accent" />
							<Stat label="Stopped" value={value(stats.stopped)} tone="text-danger" />
						</>
					) : null}
					<Link
						href={onSettings ? "/" : "/settings"}
						title={onSettings ? "Home" : "Settings"}
						aria-label={onSettings ? "Home" : "Settings"}
						className="rounded-lg border border-line bg-raised px-2.5 py-1.5 text-fg hover:border-accent/40 hover:text-accent"
					>
						{onSettings ? <IconHome className="h-5 w-5" /> : <IconSettings className="h-5 w-5" />}
					</Link>
				</div>
			</div>
		</header>
	);
}

function Stat({ label, value, tone = "" }) {
	return (
		<div className="hidden sm:block">
			<div className="text-[11px] uppercase tracking-wider text-muted">{label}</div>
			<div className={`font-semibold ${tone}`}>{value}</div>
		</div>
	);
}
