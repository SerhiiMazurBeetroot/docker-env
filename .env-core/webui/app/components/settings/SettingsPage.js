"use client";

import { useRouter } from "next/navigation";
import DisplayPicker from "../display/DisplayPicker";
import AppHeader from "../layout/AppHeader";
import ConsoleSettings from "../console/ConsoleSettings";
import LogSettings from "../logs/LogSettings";
import ThemePicker from "../theme/ThemePicker";
import DiagnosticsCard from "./DiagnosticsCard";

export default function SettingsPage() {
	const router = useRouter();

	async function signOut() {
		await fetch("/api/auth/logout", { method: "POST" });
		router.replace("/login");
	}

	return (
		<div className="min-h-screen">
			<AppHeader subtitle="Settings" />
			<main className="mx-auto max-w-3xl px-6 py-8">
				<h2 className="m-0 text-2xl font-extrabold tracking-tight">Settings</h2>
				<p className="mt-2 text-sm text-muted">Appearance, console, log view, and diagnostics.</p>

				<section className="mt-8 overflow-hidden rounded-2xl border border-line bg-panel/90">
					<div className="border-b border-line px-4 py-3 text-[11px] font-semibold uppercase tracking-wider text-muted">
						Appearance
					</div>
					<div className="px-4">
						<ThemePicker />
						<DisplayPicker />
					</div>
				</section>

				<div className="mt-8">
					<ConsoleSettings />
				</div>

				<div className="mt-8">
					<LogSettings />
				</div>

				<DiagnosticsCard />

				<section className="mt-8 overflow-hidden rounded-2xl border border-line bg-panel/90">
					<div className="border-b border-line px-4 py-3 text-[11px] font-semibold uppercase tracking-wider text-muted">
						Web UI access
					</div>
					<div className="space-y-3 px-4 py-4 text-sm text-muted">
						<p className="m-0">
							API and dashboard actions require the shared token. Show it in the CLI:{" "}
							<strong className="font-semibold text-fg">1 System → 2 Web UI → 4 Show sign-in token</strong>.
						</p>
						<button
							type="button"
							onClick={signOut}
							className="rounded-lg border border-line px-3 py-2 text-sm font-medium text-fg hover:bg-raised/80"
						>
							Sign out
						</button>
					</div>
				</section>
			</main>
		</div>
	);
}
