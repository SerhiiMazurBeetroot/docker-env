export const THEME_STORAGE_KEY = "docker-env-theme";
export const THEME_OPTIONS = ["light", "dark", "auto"];

export function readThemePreference() {
	try {
		const value = localStorage.getItem(THEME_STORAGE_KEY);
		if (THEME_OPTIONS.includes(value)) return value;
	} catch (err) {
		// ignore
	}
	return "dark";
}

export function resolvedTheme(preference) {
	if (preference === "auto") {
		if (typeof window !== "undefined" && window.matchMedia("(prefers-color-scheme: dark)").matches) {
			return "dark";
		}
		return "light";
	}
	return preference === "light" ? "light" : "dark";
}

export function applyResolvedTheme(theme) {
	if (typeof document === "undefined") return;
	document.documentElement.setAttribute("data-theme", theme);
	document.documentElement.style.colorScheme = theme;
}
