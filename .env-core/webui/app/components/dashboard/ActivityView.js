"use client";

import { IconCheck, Spinner } from "../ui/Icons";
import ConsolePanel from "./ConsolePanel";

function timeLabel(ts) {
	return new Date(ts).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit", second: "2-digit" });
}

/* Activity page: tasks run from this tab, then the console at full height. */
export default function ActivityView({ tasks = [], consoleProps }) {
	return (
		<div className="grid gap-5">
			<section className="rounded-2xl border border-line bg-panel/80" aria-label="Tasks">
				<h3 className="m-0 border-b border-line px-4 py-3 font-display text-base font-semibold">Tasks</h3>
				{tasks.length ? (
					<ul className="m-0 max-h-72 list-none divide-y divide-line overflow-y-auto p-0">
						{tasks.map((task) => (
							<li key={task.id} className="flex items-center gap-3 px-4 py-2.5 text-sm">
								<span className="w-20 shrink-0 font-mono text-[12px] text-muted">{timeLabel(task.started)}</span>
								<span
									className={`grid h-5 w-5 shrink-0 place-items-center rounded-full ${
										task.state === "running"
											? "text-warn"
											: task.state === "ok"
												? "bg-ok/15 text-ok"
												: "bg-danger/15 text-danger"
									}`}
								>
									{task.state === "running" ? <Spinner className="h-3.5 w-3.5" /> : task.state === "ok" ? <IconCheck /> : "!"}
								</span>
								<span className="min-w-0 truncate">
									<span className="font-semibold capitalize">{task.label}</span>
									<span className="text-muted"> · {task.target}</span>
								</span>
								<span className="ml-auto shrink-0 font-mono text-[12px] text-muted">
									{task.state === "running" ? "running" : `${Math.max(1, Math.round((task.ended - task.started) / 1000))} s`}
								</span>
							</li>
						))}
					</ul>
				) : (
					<p className="m-0 px-4 py-5 text-sm text-muted">
						Start, stop, rebuild or create a site and the task shows up here with its result.
					</p>
				)}
			</section>
			<ConsolePanel {...consoleProps} className="h-[60vh] min-h-[22rem]" />
		</div>
	);
}
