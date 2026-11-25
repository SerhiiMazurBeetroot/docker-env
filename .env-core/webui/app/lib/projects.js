export const URL_LABELS = {
	DOMAIN_FULL: "Site",
	DOMAIN_FRONT: "Frontend",
	DOMAIN_ADMIN: "Admin",
	DOMAIN_DB: "Database",
	DOMAIN_MAIL: "Mail",
	DOMAIN_KIBANA: "Kibana",
	DOMAIN_LOGSTASH: "Logstash",
};

// Type badges. The first pair is for the dark and neon grounds; `light:`
// swaps in a darker text and a slightly stronger tint on the white panels.
// Class strings stay literal so Tailwind keeps them.
const TYPE_TONES = {
	php: "bg-sky-400/15 text-sky-300 light:bg-sky-500/15 light:text-sky-800",
	wordpress: "bg-blue-400/15 text-blue-300 light:bg-blue-500/15 light:text-blue-800",
	wordpressnextjs: "bg-indigo-400/15 text-indigo-300 light:bg-indigo-500/15 light:text-indigo-800",
	wp: "bg-blue-400/15 text-blue-300 light:bg-blue-500/15 light:text-blue-800",
	laravel: "bg-rose-400/15 text-rose-300 light:bg-rose-500/15 light:text-rose-800",
	nextjs: "bg-zinc-400/15 text-zinc-200 light:bg-zinc-500/15 light:text-zinc-800",
	nodejs: "bg-lime-400/15 text-lime-300 light:bg-lime-500/20 light:text-lime-800",
	nodejsapi: "bg-emerald-400/15 text-emerald-300 light:bg-emerald-500/15 light:text-emerald-800",
	directus: "bg-violet-400/15 text-violet-300 light:bg-violet-500/15 light:text-violet-800",
	directusnextjs: "bg-violet-400/15 text-violet-300 light:bg-violet-500/15 light:text-violet-800",
	elastic: "bg-amber-400/15 text-amber-300 light:bg-amber-500/20 light:text-amber-800",
	elasticsearch: "bg-amber-400/15 text-amber-300 light:bg-amber-500/20 light:text-amber-800",
	bedrock: "bg-cyan-400/15 text-cyan-300 light:bg-cyan-500/15 light:text-cyan-800",
};

export function typeTone(type) {
	const key = String(type || "").toLowerCase().replace(/[\s_-]/g, "");
	return TYPE_TONES[key] || "bg-fg/10 text-muted";
}

export function projectUrls(project) {
	if (project.urls && project.urls.length) {
		return project.urls;
	}
	if (project.url) {
		return [{ key: "DOMAIN_FULL", url: project.url }];
	}
	return [];
}

export const DOZZLE_DEFAULT_URL = "http://127.0.0.1:7007";
export const PROJECT_FILTER_KEY = "docker-env-project-filter";
export const PROJECT_QUERY_KEY = "docker-env-project-query";
const PROJECT_FILTERS = new Set(["all", "running", "building", "stopped", "archived"]);

export function readProjectFilter() {
	try {
		const value = localStorage.getItem(PROJECT_FILTER_KEY);
		return PROJECT_FILTERS.has(value) ? value : "all";
	} catch (err) {
		return "all";
	}
}

export function writeProjectFilter(filter) {
	try {
		localStorage.setItem(PROJECT_FILTER_KEY, PROJECT_FILTERS.has(filter) ? filter : "all");
	} catch (err) {
		// ignore
	}
}

export function readProjectQuery() {
	try {
		return localStorage.getItem(PROJECT_QUERY_KEY) || "";
	} catch (err) {
		return "";
	}
}

export function writeProjectQuery(query) {
	try {
		localStorage.setItem(PROJECT_QUERY_KEY, query);
	} catch (err) {
		// ignore
	}
}

export function projectTypes(projects) {
	const seen = new Set();
	for (const project of projects || []) {
		const type = String(project?.type || "").trim();
		if (type) seen.add(type);
	}
	return [...seen].sort((a, b) => a.localeCompare(b));
}

export function bulkTargets(projects, action, scope) {
	const typeFilter = scope && !["all", "running", "stopped"].includes(scope) ? scope : "";
	return (projects || []).filter((project) => {
		if (isBuilding(project)) return false;
		if (typeFilter && project.type !== typeFilter) return false;
		if (action === "stop") return !!project.running;
		if (action === "start") return !project.running;
		return false;
	});
}

export function dozzleBaseUrl(system) {
	const service = (system || []).find((item) => item.id === "dozzle");
	const url = service?.urls?.find((item) => item.url)?.url;
	return String(url || DOZZLE_DEFAULT_URL).replace(/\/$/, "");
}

export function dozzleContainerUrl(container, base) {
	const root = String(base || DOZZLE_DEFAULT_URL).replace(/\/$/, "");
	if (!container) return root;
	return `${root}/show?name=${encodeURIComponent(container)}`;
}

export function serviceKind(item) {
	const state = String(item?.state || "").toLowerCase();
	const health = String(item?.health || "").toLowerCase();
	const status = String(item?.status || "").toLowerCase();

	if (state === "restarting" || status.includes("restarting")) return "restarting";
	if (health === "unhealthy" || status.includes("(unhealthy)")) return "unhealthy";
	if (state === "created" || state === "starting" || health === "starting") return "starting";
	if (state === "running" || item?.running) return "running";
	if (state === "paused") return "paused";
	if (state === "missing" || !state) return "missing";
	return "stopped";
}

export function projectKind(project) {
	if (isBuilding(project)) return "building";
	const services = project?.services || [];
	if (services.some((item) => serviceKind(item) === "unhealthy")) return "unhealthy";
	if (services.some((item) => serviceKind(item) === "restarting")) return "restarting";
	if (project?.running) return "running";
	return "stopped";
}

export function filterProjects(projects, query, filter) {
	const list = projects || [];
	const needle = query.trim().toLowerCase();
	return list.filter((project) => {
		if (filter === "running" && (!project.running || isBuilding(project))) return false;
		if (filter === "stopped" && (project.running || isBuilding(project) || isArchived(project))) return false;
		if (filter === "building" && !isBuilding(project)) return false;
		if (filter === "archived" && !isArchived(project)) return false;
		if (!needle) return true;
		const services = (project.services || [])
			.map((item) => `${item.service || ""} ${item.name || ""}`)
			.join(" ");
		const hay = `${project.domain} ${project.domainFull || ""} ${project.type || ""} ${services}`.toLowerCase();
		return hay.includes(needle);
	});
}

function isBuilding(project) {
	return String(project?.status || "").toLowerCase() === "building";
}

function isArchived(project) {
	return String(project?.status || "").toLowerCase() === "archive";
}

export function projectStats(projects) {
	const list = projects || [];
	return {
		total: list.length,
		running: list.filter((item) => item.running && !isBuilding(item) && !isArchived(item)).length,
		building: list.filter((item) => isBuilding(item)).length,
		stopped: list.filter((item) => !item.running && !isBuilding(item) && !isArchived(item)).length,
		archived: list.filter((item) => isArchived(item)).length,
	};
}
