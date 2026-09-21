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

export function readExpandAll() {
	try {
		const value = localStorage.getItem(EXPAND_STORAGE_KEY);
		if (value === "0") return false;
		if (value === "1") return true;
	} catch (err) {
		// ignore
	}
	return true;
}

export function writeExpandAll(expanded) {
	try {
		localStorage.setItem(EXPAND_STORAGE_KEY, expanded ? "1" : "0");
	} catch (err) {
		// ignore
	}
}
