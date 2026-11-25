import fs from "fs";
import { spawn } from "child_process";
import { decorateList } from "../diagnostics.js";
import { hostsFilePath, sampleProjectStats } from "../listSnapshot";
import { getCachedSnapshot, markSnapshotDirty, rememberSnapshot, snapshotCacheIsStale } from "./cache.js";
import { listProjects, listProjectsLite } from "./list.js";
import { instancesDir } from "./shared.js";

function snapshotEquals(a, b) {
	return JSON.stringify(a) === JSON.stringify(b);
}

export function streamProjectSnapshots(signal) {
	const encoder = new TextEncoder();
	let closed = false;
	let lastBody = null;
	let refreshTimer = null;
	let inFlight = false;
	let queued = false;
	let eventsChild = null;
	let watcher = null;
	let hostsWatch = null;
	let pingTimer = null;
	let statsTimer = null;

	const stream = new ReadableStream({
		start(controller) {
			const sendRaw = (chunk) => {
				if (closed) return;
				controller.enqueue(encoder.encode(chunk));
			};

			const sendSnapshot = (body) => {
				if (closed) return;
				sendRaw(`event: snapshot\ndata: ${JSON.stringify(body)}\n\n`);
			};

			const refresh = async ({ includeLite = false, force = false } = {}) => {
				if (closed) return;
				if (inFlight) {
					queued = true;
					return;
				}
				inFlight = true;
				try {
					if (includeLite && !getCachedSnapshot()) {
						const lite = await listProjectsLite();
						if (!closed && lite.body?.ok) {
							rememberSnapshot(lite.body);
							lastBody = lite.body;
							sendSnapshot(lite.body);
						}
					}
					const result = await listProjects({ force });
					if (result.body?.ok) {
						if (!snapshotEquals(lastBody, result.body)) {
							lastBody = result.body;
							sendSnapshot(result.body);
						}
						sendStats();
					} else if (!lastBody?.ok) {
						sendSnapshot(result.body);
					}
				} catch (error) {
					if (!lastBody?.ok) {
						sendSnapshot({ ok: false, error: error.message || "Could not list projects" });
					}
				} finally {
					inFlight = false;
					if (queued) {
						queued = false;
						refresh({ force: true });
					}
				}
			};

			const scheduleRefresh = () => {
				markSnapshotDirty();
				clearTimeout(refreshTimer);
				refreshTimer = setTimeout(() => refresh({ force: true }), 250);
			};

			const sendStats = async () => {
				if (closed) return;
				try {
					const projects = lastBody?.projects || getCachedSnapshot()?.projects || [];
					const sampled = await sampleProjectStats(projects);
					if (!closed && sampled?.ok) {
						sendRaw(`event: stats\ndata: ${JSON.stringify(sampled)}\n\n`);
					}
				} catch (err) {
					// keep the list usable without stats
				}
			};

			const cached = getCachedSnapshot();
			if (cached?.ok && !cached.partial) {
				const body = decorateList(cached);
				lastBody = body;
				sendSnapshot(body);
				sendStats();
			}
			if (!cached?.ok || cached.partial) {
				refresh({ includeLite: true, force: true });
			} else if (snapshotCacheIsStale()) {
				refresh({ force: true });
			}

			eventsChild = spawn("docker", ["events", "--filter", "type=container", "--format", "{{json .}}"], {
				env: process.env,
			});
			eventsChild.stdout.on("data", scheduleRefresh);
			eventsChild.stderr.on("data", () => {});
			eventsChild.on("error", () => {
				if (!closed) sendRaw(`event: error\ndata: ${JSON.stringify({ error: "docker events unavailable" })}\n\n`);
			});
			eventsChild.on("close", () => {
				if (!closed) scheduleRefresh();
			});

			try {
				const dir = instancesDir();
				if (fs.existsSync(dir)) {
					watcher = fs.watch(dir, (_event, filename) => {
						if (!filename || filename === "instances.json" || filename === "instances.log") {
							scheduleRefresh();
						}
					});
				}
			} catch (err) {
				// listing still works from docker events
			}

			// The hosts file changes without any docker event (create writes it after the
			// containers start, or someone edits it by hand). Polling stat works through the
			// single-file bind mount, where fs.watch events do not arrive.
			try {
				const hostsFile = hostsFilePath();
				if (hostsFile) {
					const onHosts = (curr, prev) => {
						if (curr.mtimeMs !== prev.mtimeMs || curr.size !== prev.size) scheduleRefresh();
					};
					fs.watchFile(hostsFile, { interval: 2000, persistent: false }, onHosts);
					hostsWatch = () => fs.unwatchFile(hostsFile, onHosts);
				}
			} catch (err) {
				// the banner still updates on the next docker event
			}

			pingTimer = setInterval(() => {
				sendRaw(": ping\n\n");
			}, 15000);
			statsTimer = setInterval(sendStats, 10000);

			const onAbort = () => {
				closed = true;
				clearTimeout(refreshTimer);
				clearInterval(pingTimer);
				clearInterval(statsTimer);
				eventsChild?.kill("SIGTERM");
				watcher?.close();
				hostsWatch?.();
				signal?.removeEventListener("abort", onAbort);
				try {
					controller.close();
				} catch (err) {
					// already closed
				}
			};

			if (signal) {
				if (signal.aborted) onAbort();
				else signal.addEventListener("abort", onAbort);
			}
		},
		cancel() {
			closed = true;
			clearTimeout(refreshTimer);
			clearInterval(pingTimer);
			clearInterval(statsTimer);
			eventsChild?.kill("SIGTERM");
			watcher?.close();
			hostsWatch?.();
		},
	});

	return { stream };
}
