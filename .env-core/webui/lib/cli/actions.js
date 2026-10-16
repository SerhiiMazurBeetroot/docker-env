import { catalogTypeIds, loadProjectCatalog } from "../catalog.js";
import { wipFeatureDenied } from "../features.js";
import { normalizeProjectDomain } from "../domain.js";
import { readVersionCatalog, versionChoiceError } from "../versions.js";
import { streamLockedCli } from "./stream.js";
import {
	ACTIONS,
	BULK_ACTIONS,
	CREATE_OPTION_KEYS,
	SERVICE_ACTIONS,
	SYSTEM_ACTIONS,
	SYSTEM_IDS,
	isSafeBulkScope,
	isSafeCreateOption,
	isSafeDomain,
	isSafeServiceName,
} from "./shared.js";

function actionGuard(action, domain) {
	if (!ACTIONS.has(action)) {
		return { status: 404, body: { ok: false, error: "Not found" } };
	}
	if (!isSafeDomain(domain)) {
		return { status: 400, body: { ok: false, error: "Invalid domain" } };
	}
	return null;
}

function systemGuard(id, action) {
	if (!SYSTEM_IDS.has(id) || !SYSTEM_ACTIONS.has(action)) {
		return { status: 404, body: { ok: false, error: "Not found" } };
	}
	return null;
}

function serviceGuard(domain, action, service) {
	if (!SERVICE_ACTIONS.has(action)) {
		return { status: 404, body: { ok: false, error: "Not found" } };
	}
	if (!isSafeDomain(domain) || !isSafeServiceName(service)) {
		return { status: 400, body: { ok: false, error: "Invalid service" } };
	}
	return null;
}

export function streamProjectAction(action, domain, signal) {
	const guard = actionGuard(action, domain);
	if (guard) return { error: guard };

	const args = action === "delete" ? ["delete", domain] : [action, domain];
	return streamLockedCli(args, `domain:${domain}`, signal, {
		domain,
		action,
		target: domain,
		timeoutMs: action === "delete" ? 10 * 60 * 1000 : undefined,
	});
}

export async function listProjectTypes() {
	try {
		const data = await loadProjectCatalog();
		if (data?.ok && Array.isArray(data.types)) {
			return { status: 200, body: { ...data, versions: readVersionCatalog() } };
		}
	} catch (err) {
		// fall through
	}
	return { status: 500, body: { ok: false, error: "Could not list project types" } };
}

export async function streamCreateProject(type, domain, options, signal) {
	const denied = wipFeatureDenied("webui.create");
	if (denied) return { error: denied };

	let catalog;
	try {
		catalog = await loadProjectCatalog();
	} catch (err) {
		return { error: { status: 500, body: { ok: false, error: "Could not load project catalog" } } };
	}

	const name = normalizeProjectDomain(domain);
	if (!catalogTypeIds(catalog).has(type)) {
		return { error: { status: 400, body: { ok: false, error: "Invalid project type" } } };
	}
	if (!isSafeDomain(name)) {
		return { error: { status: 400, body: { ok: false, error: "Invalid domain. Use letters, numbers, and hyphens." } } };
	}

	const extras = [];
	for (const [key, value] of Object.entries(options || {})) {
		if (!value) continue;
		if (!CREATE_OPTION_KEYS.has(key) || !isSafeCreateOption(String(value))) {
			return { error: { status: 400, body: { ok: false, error: `Invalid option ${key}` } } };
		}
		extras.push(`${key}=${value}`);
	}

	const unknownVersion = versionChoiceError(options);
	if (unknownVersion) {
		return { error: { status: 400, body: { ok: false, error: unknownVersion } } };
	}

	return streamLockedCli(["create", type, name, ...extras], `domain:${name}`, signal, {
		domain: name,
		action: "create",
		target: name,
		timeoutMs: 20 * 60 * 1000,
	});
}

export function streamBulkAction(action, scope, signal) {
	if (!BULK_ACTIONS.has(action) || !isSafeBulkScope(scope)) {
		return { error: { status: 400, body: { ok: false, error: "Invalid bulk action" } } };
	}

	return streamLockedCli(["bulk", action, scope], "bulk", signal, {
		action,
		scope,
		target: scope === "all" || scope === "running" || scope === "stopped" ? `all ${scope}` : scope,
		timeoutMs: 20 * 60 * 1000,
	});
}

export function streamSystemAction(id, action, signal) {
	const guard = systemGuard(id, action);
	if (guard) return { error: guard };

	return streamLockedCli(["system", id, action], `system:${id}`, signal, {
		id,
		action,
		target: id,
	});
}

export function streamServiceAction(domain, action, service, signal) {
	const guard = serviceGuard(domain, action, service);
	if (guard) return { error: guard };

	return streamLockedCli(["service", domain, action, service], `domain:${domain}`, signal, {
		domain,
		action,
		service,
		target: `${domain}/${service}`,
	});
}
