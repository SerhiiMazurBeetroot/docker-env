"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { appendCliLog, readConsoleOpen, readSse, visibleLog, writeConsoleOpen } from "../../lib/logs";
import { filterProjects, projectStats, projectTypes, bulkTargets, dozzleBaseUrl, dozzleContainerUrl, readProjectFilter, readProjectQuery, writeProjectFilter, writeProjectQuery } from "../../lib/projects";
import { expectFromAction, pendingResolved } from "../../lib/waiting";
import { useSnapshot } from "../snapshot/SnapshotProvider";
import { useConsoleSettings } from "../console/ConsoleSettingsProvider";
import { useDisplay } from "../display/DisplayProvider";
import AppHeader from "../layout/AppHeader";
import Console from "./Console";
import CreateProjectModal from "./CreateProjectModal";
import ProjectDetail from "./ProjectDetail";
import ProjectList from "./ProjectList";
import ProjectToolbar from "./ProjectToolbar";
import SystemSection from "./SystemSection";

export default function Dashboard() {
	const { projects, system, error } = useSnapshot();
	const { density } = useDisplay();
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

	useEffect(() => {
		setLogOpen(readConsoleOpen());
		setFilter(readProjectFilter());
		setQuery(readProjectQuery());
		setConsoleReady(true);
	}, []);

	useEffect(() => {
		if (!consoleReady) return;
		writeConsoleOpen(logOpen);
		writeProjectFilter(filter);
		writeProjectQuery(query);
	}, [consoleReady, logOpen, filter, query]);

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
		} finally {
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
			`Delete ${domain}?\n\nStops containers if they exist, then removes site files and the instances.log row. Matching images and volumes are removed when present.`
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
	];

	return (
		<div className="flex h-screen flex-col overflow-hidden">
			<AppHeader
				stats={stats}
				loading={projects == null}
				createBusy={Object.values(busy).includes("create")}
				onCreate={() => setCreateOpen(true)}
			/>
			<div className="flex min-h-0 flex-1">
				<main className="min-w-0 flex-1 overflow-y-auto">
					<div className={`mx-auto px-6 py-6 ${density === "grid" ? "max-w-7xl" : "max-w-6xl"}`}>
						<SystemSection
							services={system}
							loading={projects == null}
							busy={busy}
							pending={pending}
							onAction={runSystemAction}
							onLogs={followLogs}
							logContainer={logContainer}
							dozzleBase={dozzleBase}
						/>
						<ProjectToolbar
							filters={filters}
							filter={filter}
							onFilter={setFilter}
							query={query}
							onQuery={setQuery}
							loading={projects == null}
							projects={projects}
							types={types}
							busy={busy.bulk || ""}
							onBulk={runBulk}
						/>
						<ProjectList
							projects={projects}
							visible={visible}
							error={error}
							busy={busy}
							pending={pending}
							onAction={runAction}
							onLogs={followLogs}
							onServiceAction={runServiceAction}
							onOpen={setDetailDomain}
							onHosts={runHosts}
							onDelete={runDelete}
							selectedDomain={detailDomain}
							logContainer={logContainer}
							dozzleBase={dozzleBase}
						/>
					</div>
				</main>
				<Console
					mode={consoleMode}
					log={log}
					entries={logEntries}
					title={logTitle}
					logOpen={logOpen}
					logLive={logLive}
					onToggle={() => setLogOpen((open) => !open)}
					onStop={stopLogs}
					dozzleUrl={consoleMode === "logs" && logContainer ? dozzleContainerUrl(logContainer, dozzleBase) : ""}
					onClear={() => {
						setLog("");
						setLogEntries([]);
					}}
				/>
			</div>
			<ProjectDetail
				domain={detailDomain}
				onClose={() => setDetailDomain("")}
				onDelete={runDelete}
			/>
			<CreateProjectModal
				open={createOpen}
				onClose={() => setCreateOpen(false)}
				onCreate={runCreate}
				busy={Object.values(busy).includes("create")}
			/>
		</div>
	);
}
