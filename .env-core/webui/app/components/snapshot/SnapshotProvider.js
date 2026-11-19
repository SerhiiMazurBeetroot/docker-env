"use client";

import { usePathname } from "next/navigation";
import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";

const RECONNECT_MS = 3000;

let memory = {
	projects: null,
	system: [],
	error: "",
	resources: {},
	setup: null,
	features: {},
};

const SnapshotContext = createContext(memory);

function nextSnapshot(current, data) {
	const incomingProjects = data.projects || [];
	const incomingSystem = Array.isArray(data.system) ? data.system : [];
	let projects = incomingProjects;
	let system = incomingSystem;

	if (data.partial && Array.isArray(current.projects) && current.projects.some((item) => item.services?.length)) {
		const lite = new Map(incomingProjects.map((item) => [item.domain, item]));
		projects = current.projects.map((item) => {
			const hit = lite.get(item.domain);
			return hit
				? {
						...item,
						running: hit.running,
						status: hit.status,
						hosts: hit.hosts || item.hosts,
						urls: hit.urls?.length ? hit.urls : item.urls,
						guide: hit.guide || item.guide || "",
						notice: hit.notice !== undefined ? hit.notice : item.notice,
					}
				: item;
		});
	}

	if (data.partial && Array.isArray(current.system) && current.system.length) {
		const running = new Map(incomingSystem.map((item) => [item.id, item.running]));
		system = current.system.map((item) =>
			running.has(item.id) ? { ...item, running: running.get(item.id) } : item
		);
	}

	return {
		projects,
		system,
		error: "",
		resources: current.resources || {},
		setup: data.setup || current.setup || null,
		features: data.features || current.features || {},
	};
}

export function SnapshotProvider({ children }) {
	const [snapshot, setSnapshot] = useState(memory);
	const hasSnapshot = useRef(memory.projects != null);

	useEffect(() => {
		memory = snapshot;
	}, [snapshot]);

	const applySnapshot = useCallback((data) => {
		if (!data?.ok) {
			if (!hasSnapshot.current) {
				setSnapshot((current) => ({ ...current, error: data?.error || "Failed to load projects" }));
			}
			return;
		}
		hasSnapshot.current = true;
		setSnapshot((current) => nextSnapshot(current, data));
	}, []);

	// The provider lives in the root layout, so it stays mounted across client-side
	// navigation. Skip the stream on /login (it would only get a 401), and reopen it
	// once the user leaves that page after signing in.
	const pathname = usePathname();
	const onLogin = pathname === "/login" || pathname?.startsWith("/login/");

	useEffect(() => {
		if (onLogin) {
			return undefined;
		}
		let source = null;
		let retryTimer = null;
		let stopped = false;
		const onSnapshot = (event) => {
			try {
				applySnapshot(JSON.parse(event.data));
			} catch (err) {
				setSnapshot((current) => ({ ...current, error: err.message }));
			}
		};
		const onStats = (event) => {
			try {
				const payload = JSON.parse(event.data);
				if (payload?.ok && payload.stats) {
					setSnapshot((current) => ({ ...current, resources: payload.stats }));
				}
			} catch (err) {
				// ignore a bad stats chunk
			}
		};
		// EventSource retries network drops by itself, but an HTTP error (401, 5xx)
		// closes it for good. Reopen it after a short delay so the dashboard recovers
		// when the session or the dev server comes back.
		const onError = () => {
			if (stopped || !source || source.readyState !== EventSource.CLOSED) {
				return;
			}
			clearTimeout(retryTimer);
			retryTimer = setTimeout(connect, RECONNECT_MS);
		};
		function connect() {
			if (stopped) {
				return;
			}
			if (source) {
				source.close();
			}
			source = new EventSource("/api/events/stream");
			source.addEventListener("snapshot", onSnapshot);
			source.addEventListener("stats", onStats);
			source.addEventListener("error", onError);
		}
		connect();
		return () => {
			stopped = true;
			clearTimeout(retryTimer);
			if (source) {
				source.removeEventListener("snapshot", onSnapshot);
				source.removeEventListener("stats", onStats);
				source.removeEventListener("error", onError);
				source.close();
			}
		};
	}, [applySnapshot, onLogin]);

	const value = useMemo(() => {
		const resources = snapshot.resources || {};
		const projects = snapshot.projects?.map((item) => ({
			...item,
			resources: resources[item.domain] || item.resources,
		}));
		return {
			projects,
			system: snapshot.system,
			error: snapshot.error,
			setup: snapshot.setup || null,
			features: snapshot.features || {},
		};
	}, [snapshot]);

	return <SnapshotContext.Provider value={value}>{children}</SnapshotContext.Provider>;
}

export function useSnapshot() {
	return useContext(SnapshotContext);
}
