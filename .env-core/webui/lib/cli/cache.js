let snapshotCache = null;
let cacheDirty = true;
let cacheAt = 0;
const CACHE_TTL_MS = 20_000;

function mergeLiteIntoCache(full, lite) {
	const byDomain = new Map((lite.projects || []).map((item) => [item.domain, item]));
	const byId = new Map((lite.system || []).map((item) => [item.id, item]));
	return {
		...full,
		ok: true,
		partial: false,
		projects: (full.projects || []).map((item) => {
			const hit = byDomain.get(item.domain);
			return hit ? { ...item, running: hit.running, status: hit.status, hosts: hit.hosts || item.hosts } : item;
		}),
		system: (full.system || []).map((item) => {
			const hit = byId.get(item.id);
			return hit ? { ...item, running: hit.running, state: hit.state || item.state } : item;
		}),
	};
}

export function getCachedSnapshot() {
	return snapshotCache;
}

export function snapshotCacheIsStale() {
	if (cacheDirty || !snapshotCache?.ok || snapshotCache.partial) return true;
	return Date.now() - cacheAt > CACHE_TTL_MS;
}

export function rememberSnapshot(body) {
	if (!body?.ok) return;
	if (body.partial && snapshotCache && !snapshotCache.partial) {
		snapshotCache = mergeLiteIntoCache(snapshotCache, body);
		return;
	}
	snapshotCache = body;
	if (!body.partial) {
		cacheDirty = false;
		cacheAt = Date.now();
	}
}

export function freshSnapshot() {
	if (cacheDirty || !snapshotCache?.ok || snapshotCache.partial) return null;
	return snapshotCache;
}

export function markSnapshotDirty() {
	cacheDirty = true;
}
