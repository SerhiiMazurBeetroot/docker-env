export const DISPLAY_STORAGE_KEY = "docker-env-card-density";
export const DISPLAY_OPTIONS = ["comfortable", "compact", "grid"];

export function readCardDensity() {
	try {
		const value = localStorage.getItem(DISPLAY_STORAGE_KEY);
		if (DISPLAY_OPTIONS.includes(value)) return value;
	} catch (err) {
		// ignore
	}
	return "comfortable";
}

export function writeCardDensity(density) {
	try {
		localStorage.setItem(DISPLAY_STORAGE_KEY, DISPLAY_OPTIONS.includes(density) ? density : "comfortable");
	} catch (err) {
		// ignore
	}
}

export const EXPAND_STORAGE_KEY = "docker-env-expand-all";
// Compact rows keep their own expand state and start collapsed, so "Expand all" on the
// wider layouts does not turn the one-line list into tall rows.
export const EXPAND_COMPACT_STORAGE_KEY = "docker-env-expand-all-compact";

function expandKey(density) {
	return density === "compact" ? EXPAND_COMPACT_STORAGE_KEY : EXPAND_STORAGE_KEY;
}

export function readExpandAll(density) {
	try {
		const value = localStorage.getItem(expandKey(density));
		if (value === "0") return false;
		if (value === "1") return true;
	} catch (err) {
		// ignore
	}
	return density !== "compact";
}

export function writeExpandAll(expanded, density) {
	try {
		localStorage.setItem(expandKey(density), expanded ? "1" : "0");
	} catch (err) {
		// ignore
	}
}

// "Group by type" on the Sites page. Off by default: with a few sites, one grid is easier to scan.
export const GROUP_STORAGE_KEY = "docker-env-group-by-type";

export function readGroupByType() {
	try {
		return localStorage.getItem(GROUP_STORAGE_KEY) === "1";
	} catch (err) {
		return false;
	}
}

export function writeGroupByType(enabled) {
	try {
		localStorage.setItem(GROUP_STORAGE_KEY, enabled ? "1" : "0");
	} catch (err) {
		// ignore
	}
}
