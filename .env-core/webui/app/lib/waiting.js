export function expectFromAction(action) {
	if (action === "stop" || action === "delete") return "stopped";
	if (action === "start" || action === "restart" || action === "rebuild" || action === "create") return "running";
	return null;
}

export function waitLabel(expect, action) {
	if (action === "rebuild") return "rebuilding";
	if (action === "create") return "creating";
	if (action === "delete") return "deleting";
	if (action === "restart") return "restarting";
	if (expect === "stopped" || action === "stop") return "stopping";
	if (expect === "running" || action === "start") return "starting";
	if (expect === "building" || action === "build") return "building";
	return "waiting";
}

export function isBuildingProject(project) {
	return String(project?.status || "").toLowerCase() === "building";
}

export function isStartingState(state) {
	const value = String(state || "").toLowerCase();
	return value === "created" || value === "restarting" || value === "starting" || value === "removing";
}

export function pendingResolved(key, expect, projects, system) {
	const wantRunning = expect === "running";

	if (key.startsWith("system:")) {
		const id = key.slice(7);
		const service = (system || []).find((item) => item.id === id);
		return service ? !!service.running === wantRunning : false;
	}

	if (key.startsWith("svc:")) {
		const rest = key.slice(4);
		const split = rest.indexOf(":");
		if (split < 0) return false;
		const domain = rest.slice(0, split);
		const serviceName = rest.slice(split + 1);
		const project = (projects || []).find((item) => item.domain === domain);
		const service = (project?.services || []).find(
			(item) => item.service === serviceName || item.name === serviceName
		);
		return service ? !!service.running === wantRunning : false;
	}

	const project = (projects || []).find((item) => item.domain === key);
	if (!project) return expect === "stopped";
	return !!project.running === wantRunning;
}
