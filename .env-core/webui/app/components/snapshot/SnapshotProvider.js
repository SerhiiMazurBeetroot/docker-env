"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";

let memory = {
	projects: null,
	system: [],
	error: "",
	resources: {},
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

	return { projects, system, error: "", resources: current.resources || {} };
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

	useEffect(() => {
		const source = new EventSource("/api/events/stream");
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
		source.addEventListener("snapshot", onSnapshot);
		source.addEventListener("stats", onStats);
		return () => {
			source.removeEventListener("snapshot", onSnapshot);
			source.removeEventListener("stats", onStats);
			source.close();
		};
	}, [applySnapshot]);

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
		};
	}, [snapshot]);

	return <SnapshotContext.Provider value={value}>{children}</SnapshotContext.Provider>;
}

export function useSnapshot() {
	return useContext(SnapshotContext);
}
