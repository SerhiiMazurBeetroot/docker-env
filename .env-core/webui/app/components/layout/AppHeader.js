"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import ActionButton from "../ui/ActionButton";
import { IconDocs, IconHome, IconPlus, IconSettings, Spinner } from "../ui/Icons";

export default function AppHeader({
	loading,
	subtitle = "Local container console",
	createBusy = false,
	onCreate,
}) {
	const pathname = usePathname();
	const onSettings = pathname === "/settings" || pathname?.startsWith("/settings/");
	const onDocs = pathname === "/docs" || pathname?.startsWith("/docs/");
	const showCreate = typeof onCreate === "function";

	return (
		<header className="sticky top-0 z-40 shrink-0 border-b border-line bg-ink/80 backdrop-blur-xl">
			<div className="flex items-center gap-4 px-6 py-3">
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

				<div className="ml-auto flex items-center gap-2 text-sm">
					{showCreate ? (
						<ActionButton
							label="Create"
							tone="start"
							icon={<IconPlus />}
							size="sm"
							disabled={loading || createBusy}
							onClick={() => onCreate?.()}
						/>
					) : null}
					<Link
						href="/docs"
						title="Documentation"
						aria-label="Documentation"
						aria-current={onDocs ? "page" : undefined}
						className={`rounded-lg border px-2.5 py-1.5 hover:border-accent/40 hover:text-accent ${
							onDocs ? "border-accent/40 bg-raised text-accent" : "border-line bg-raised text-fg"
						}`}
					>
						<IconDocs />
					</Link>
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
