"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { useSearchParams } from "next/navigation";
import { appendCliLog, readSse, visibleLog } from "../../lib/logs";
import { filterProjects, projectStats, projectTypes, bulkTargets, dozzleBaseUrl, dozzleContainerUrl, readProjectFilter, readProjectQuery, writeProjectFilter, writeProjectQuery } from "../../lib/projects";
import { expectFromAction, pendingResolved } from "../../lib/waiting";
import { useSnapshot } from "../snapshot/SnapshotProvider";
import { useConsoleSettings } from "../console/ConsoleSettingsProvider";
import AppShell from "../layout/AppShell";
import ActivityView from "./ActivityView";
import ConsoleDock from "./ConsoleDock";
import CreateProjectModal from "./CreateProjectModal";
import ProjectDetail from "./ProjectDetail";
import SiteGrid from "./SiteGrid";
import SummaryStats from "./SummaryStats";
import ProjectToolbar from "./ProjectToolbar";
import SystemView from "./SystemView";
import SetupChecklist from "./SetupChecklist";
import { reportError } from "../../lib/reportError";
import { IconPlus } from "../ui/Icons";

const VIEWS = {
	sites: { eyebrow: "Local containers", title: "Sites" },
	system: { eyebrow: "Shared services", title: "System" },
	activity: { eyebrow: "Tasks and logs", title: "Activity" },
};

export default function Dashboard() {
	const { projects, system, error, setup, features, history } = useSnapshot();
	const searchParams = useSearchParams();
	const view = VIEWS[searchParams.get("view")] ? searchParams.get("view") : "sites";
	const [tasks, setTasks] = useState([]);
	const { autoOpen } = useConsoleSettings();
	const [busy, setBusy] = useState({});
	const [pending, setPending] = useState({});
	const [log, setLog] = useState("");
	const [query, setQuery] = useState("");
	const [filter, setFilter] = useState("all");
	const [logOpen, setLogOpen] = useState(false);
	const [logLive, setLogLive] = useState(false);
	const [consoleReady, setConsoleReady] = useState(false);
	const [consoleMode, setConsoleMode] = useState("cli");
	const [logEntries, setLogEntries] = useState([]);
	const [logTitle, setLogTitle] = useState("Console");
	const [logContainer, setLogContainer] = useState("");
	const [detailDomain, setDetailDomain] = useState("");
	const [createOpen, setCreateOpen] = useState(false);
	const logsSource = useRef(null);
	const taskSeq = useRef(0);

	useEffect(() => {
		setFilter(readProjectFilter());
		setQuery(readProjectQuery());
		setConsoleReady(true);
	}, []);

	useEffect(() => {
		if (!consoleReady) return;
		writeProjectFilter(filter);
		writeProjectQuery(query);
	}, [consoleReady, filter, query]);

	useEffect(() => {
		return () => {
			logsSource.current?.close();
		};
	}, []);

	function stopLogs() {
		logsSource.current?.close();
		logsSource.current = null;
		setLogLive(false);
	}

	function followLogs(container, label) {
		if (!container) return;
		stopLogs();
		setConsoleMode("logs");
		setLogEntries([]);
		setLog("");
		setLogTitle(label || container);
		setLogContainer(container);
		setLogOpen(true);
		setLogLive(true);

		const source = new EventSource(`/api/containers/${encodeURIComponent(container)}/logs`);
		logsSource.current = source;

		source.addEventListener("entry", (event) => {
			try {
				const entry = JSON.parse(event.data);
				setLogEntries((current) => {
					const base = current.length > 1800 ? current.slice(-1400) : current;
					return [...base, entry];
				});
			} catch (err) {
				// ignore a bad chunk
			}
		});

		source.addEventListener("fail", (event) => {
			try {
				const payload = JSON.parse(event.data);
				setLogEntries((current) => [
					...current,
					{ ts: "", level: "error", message: payload.error || "Log stream failed", fields: [] },
				]);
			} catch (err) {
				// ignore
			}
			setLogLive(false);
		});

		source.addEventListener("done", () => {
			setLogLive(false);
			source.close();
			if (logsSource.current === source) logsSource.current = null;
		});

		source.onerror = () => {
			if (source.readyState === EventSource.CLOSED) {
				setLogLive(false);
			}
		};
	}

	useEffect(() => {
		setPending((current) => {
			const next = { ...current };
			for (const [key, expect] of Object.entries(current)) {
				if (pendingResolved(key, expect, projects, system)) {
					delete next[key];
				}
			}
			return next;
		});
	}, [projects, system]);

	useEffect(() => {
		const keys = Object.keys(pending);
		if (!keys.length) return undefined;
		const timer = setTimeout(() => {
			setPending({});
		}, 90000);
		return () => clearTimeout(timer);
	}, [pending]);

	async function runStream(path, key, label, action, pendingKeys = [], body = null) {
		const expect = expectFromAction(action);
		let succeeded = false;
		const waitKeys = pendingKeys.length ? pendingKeys : [key];
		stopLogs();
		setConsoleMode("cli");
		setLogContainer("");
		setLogTitle("Console");
		setBusy((current) => ({ ...current, [key]: label }));
		taskSeq.current += 1;
		const taskId = taskSeq.current;
		const target = String(key).replace(/^(system|hosts|svc):/, "").replace(/:/g, " · ");
		setTasks((current) => [{ id: taskId, label, target, state: "running", started: Date.now() }, ...current].slice(0, 50));
		if (expect) {
			setPending((current) => {
				const next = { ...current };
				for (const waitKey of waitKeys) next[waitKey] = expect;
				return next;
			});
		}
		if (autoOpen) setLogOpen(true);
		setLogLive(true);
		setLog(`${label}…\n`);
		try {
			const response = await fetch(path, {
				method: "POST",
				headers: body ? { "Content-Type": "application/json" } : undefined,
				body: body ? JSON.stringify(body) : undefined,
			});
			const contentType = response.headers.get("content-type") || "";
			if (!contentType.includes("text/event-stream")) {
				const data = await response.json();
				setLog(visibleLog(data.log || data.error || ""));
				succeeded = !!data.ok;
				return;
			}
			await readSse(response, (event) => {
				if (event.type === "log") {
					if (autoOpen) setLogOpen(true);
					setLog((current) => appendCliLog(current, event.text));
					return;
				}
				if (event.type === "done") {
					succeeded = !!event.ok;
					if (event.log) {
						setLog(visibleLog(event.log));
					} else if (event.error) {
						setLog((current) => appendCliLog(current, `\n${event.error}`));
					}
				}
			});
		} catch (err) {
			setLog((current) => appendCliLog(current, `\n${err.message}`));
			reportError({
				source: "browser",
				action: label,
				target: key,
				message: err.message || "Request failed",
			});
		} finally {
			setTasks((current) =>
				current.map((task) =>
					task.id === taskId ? { ...task, state: succeeded ? "ok" : "failed", ended: Date.now() } : task
				)
			);
			setLogLive(false);
			setBusy((current) => {
				const next = { ...current };
				delete next[key];
				return next;
			});
			if (!succeeded && expect) {
				setPending((current) => {
					const next = { ...current };
					for (const waitKey of waitKeys) delete next[waitKey];
					return next;
				});
			}
		}
	}

	function runAction(action, domain) {
		return runStream(`/api/projects/${encodeURIComponent(domain)}/${action}`, domain, action, action);
	}

	function runCreate({ type, domain, options }) {
		setCreateOpen(false);
		return runStream("/api/projects", domain, "create", "create", [domain], {
			type,
			domain,
			options,
		});
	}

	function runDelete(domain) {
		if (!domain) return;
		const ok = window.confirm(
			`Delete ${domain}?\n\nStops containers if they exist, then removes site files and the site record. Matching images and volumes are removed when present.`
		);
		if (!ok) return;
		if (detailDomain === domain) setDetailDomain("");
		return runAction("delete", domain);
	}

	function runSystemAction(action, id) {
		return runStream(`/api/system/${encodeURIComponent(id)}/${action}`, `system:${id}`, action, action);
	}

	function runServiceAction(action, domain, service) {
		return runStream(
			`/api/projects/${encodeURIComponent(domain)}/services/${encodeURIComponent(service)}/${action}`,
			`svc:${domain}:${service}`,
			`${action} ${service}`,
			action
		);
	}

	function runHosts(action, domain) {
		const label = action === "rem" ? "remove extras" : "add extras";
		return runStream(
			`/api/projects/${encodeURIComponent(domain)}/hosts/${action}`,
			`hosts:${domain}`,
			label,
			"hosts"
		);
	}

	function runBulk(action, scope) {
		const targets = bulkTargets(projects, action, scope);
		if (!targets.length) {
			stopLogs();
			setConsoleMode("cli");
			setLogTitle("Console");
			if (autoOpen) setLogOpen(true);
			setLog(`No projects to ${action} (${scope}).\n`);
			return;
		}
		if (action === "stop") {
			const names = targets.map((item) => item.domain).join(", ");
			const ok = window.confirm(`Stop ${targets.length} running project${targets.length === 1 ? "" : "s"} (${scope})?\n${names}\n\nThis uses docker_stop_all (compose down).`);
			if (!ok) return;
		}
		const label = action === "stop" ? `stop ${scope}` : `start ${scope}`;
		return runStream(
			`/api/bulk/${encodeURIComponent(action)}?scope=${encodeURIComponent(scope)}`,
			"bulk",
			label,
			action,
			targets.map((item) => item.domain)
		);
	}

	const dozzleBase = useMemo(() => dozzleBaseUrl(system), [system]);
	const stats = useMemo(() => projectStats(projects), [projects]);
	const types = useMemo(() => projectTypes(projects), [projects]);
	const visible = useMemo(
		() => filterProjects(projects, query, filter),
		[projects, query, filter]
	);
	const filters = [
		{ id: "all", label: "All", count: stats.total },
		{ id: "running", label: "Running", count: stats.running },
		{ id: "building", label: "Building", count: stats.building },
		{ id: "stopped", label: "Stopped", count: stats.stopped },
		{ id: "archived", label: "Archived", count: stats.archived },
	];

	const consoleProps = {
		mode: consoleMode,
		log,
		entries: logEntries,
		title: logTitle,
		logLive,
		onStop: stopLogs,
		dozzleUrl: consoleMode === "logs" && logContainer ? dozzleContainerUrl(logContainer, dozzleBase) : "",
		onClear: () => {
			setLog("");
			setLogEntries([]);
		},
	};
	const runningTasks = tasks.filter((task) => task.state === "running").length;
	const canCreate = !!features?.["webui.create"];
	const createBusy = Object.values(busy).includes("create");
	const loading = projects == null;

	return (
		<AppShell active={view} badges={{ activity: runningTasks || null }}>
			<main className="w-full px-4 pb-8 pt-6 sm:px-8">
				<header className="mb-5 flex flex-wrap items-end gap-3">
					<div className="min-w-0">
						<p className="m-0 font-mono text-[11px] uppercase tracking-[0.14em] text-muted">{VIEWS[view].eyebrow}</p>
						<h2 className="m-0 mt-1 font-display text-3xl font-semibold">{VIEWS[view].title}</h2>
					</div>
					{view === "sites" && canCreate ? (
						<button
							type="button"
							disabled={loading || createBusy}
							onClick={() => setCreateOpen(true)}
							className="ml-auto inline-flex h-9 items-center gap-2 rounded-lg bg-accent px-3.5 text-sm font-semibold text-ink shadow-[0_0_18px_-2px_rgb(var(--accent)/0.6)] transition hover:brightness-110 disabled:opacity-50"
						>
							<IconPlus />
							New site
						</button>
					) : null}
				</header>

				{view === "sites" ? (
					<>
						<SetupChecklist setup={setup} loading={loading} busy={busy} onHosts={runHosts} />
						<SummaryStats projects={projects} history={history} />
						<ProjectToolbar
							filters={filters}
							filter={filter}
							onFilter={setFilter}
							query={query}
							onQuery={setQuery}
							loading={loading}
							projects={projects}
							types={types}
							busy={busy.bulk || ""}
							onBulk={runBulk}
						/>
						<SiteGrid
							projects={projects}
							visible={visible}
							error={error}
							history={history}
							busy={busy}
							pending={pending}
							onAction={runAction}
							onLogs={followLogs}
							onServiceAction={runServiceAction}
							onOpen={setDetailDomain}
							onHosts={runHosts}
							onDelete={runDelete}
							onCreate={canCreate ? () => setCreateOpen(true) : undefined}
							selectedDomain={detailDomain}
							logContainer={logContainer}
							dozzleBase={dozzleBase}
						/>
					</>
				) : null}

				{view === "system" ? (
					<SystemView
						services={system}
						loading={loading}
						setup={setup}
						busy={busy}
						pending={pending}
						onAction={runSystemAction}
						onLogs={followLogs}
						onHosts={runHosts}
						logContainer={logContainer}
						dozzleBase={dozzleBase}
					/>
				) : null}

				{view === "activity" ? <ActivityView tasks={tasks} consoleProps={consoleProps} /> : null}
			</main>

			{view !== "activity" ? (
				<ConsoleDock open={logOpen} onToggle={() => setLogOpen((open) => !open)} consoleProps={consoleProps} />
			) : null}

			<ProjectDetail
				domain={detailDomain}
				onClose={() => setDetailDomain("")}
				onDelete={runDelete}
			/>
			<CreateProjectModal
				open={createOpen}
				onClose={() => setCreateOpen(false)}
				onCreate={runCreate}
				busy={createBusy}
			/>
		</AppShell>
	);
}
