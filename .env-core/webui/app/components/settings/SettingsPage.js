"use client";

import DisplayPicker from "../display/DisplayPicker";
import AppHeader from "../layout/AppHeader";
import ConsoleSettings from "../console/ConsoleSettings";
import LogSettings from "../logs/LogSettings";
import ThemePicker from "../theme/ThemePicker";

export default function SettingsPage() {
	return (
		<div className="min-h-screen">
			<AppHeader subtitle="Settings" />
			<main className="mx-auto max-w-3xl px-6 py-8">
				<h2 className="m-0 text-2xl font-extrabold tracking-tight">Settings</h2>
				<p className="mt-2 text-sm text-muted">Appearance, console, and log view. Saved in this browser.</p>

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
			</main>
		</div>
	);
}
