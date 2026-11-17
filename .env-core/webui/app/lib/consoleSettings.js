export const CONSOLE_AUTO_OPEN_KEY = "docker-env-console-auto-open";
export const CONSOLE_AUTO_SCROLL_KEY = "docker-env-console-auto-scroll";

export function readConsoleAutoOpen() {
	try {
		const value = localStorage.getItem(CONSOLE_AUTO_OPEN_KEY);
		if (value === null) return true;
		return value === "1";
	} catch (err) {
		return true;
	}
}

export function writeConsoleAutoOpen(open) {
	try {
		localStorage.setItem(CONSOLE_AUTO_OPEN_KEY, open ? "1" : "0");
	} catch (err) {
		// ignore
	}
}

export function readConsoleAutoScroll() {
	try {
		const value = localStorage.getItem(CONSOLE_AUTO_SCROLL_KEY);
		if (value === null) return true;
		return value === "1";
	} catch (err) {
		return true;
	}
}

export function writeConsoleAutoScroll(enabled) {
	try {
		localStorage.setItem(CONSOLE_AUTO_SCROLL_KEY, enabled ? "1" : "0");
	} catch (err) {
		// ignore
	}
}
