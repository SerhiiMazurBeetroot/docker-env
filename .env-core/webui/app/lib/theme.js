export const THEME_STORAGE_KEY = "docker-env-theme";
export const THEME_OPTIONS = ["neon", "light", "dark", "auto"];
export const DEFAULT_THEME = "neon";

export function readThemePreference() {
	try {
		const value = localStorage.getItem(THEME_STORAGE_KEY);
		if (THEME_OPTIONS.includes(value)) return value;
	} catch (err) {
		// ignore
	}
	return DEFAULT_THEME;
}

export function resolvedTheme(preference) {
	if (preference === "auto") {
		if (typeof window !== "undefined" && window.matchMedia("(prefers-color-scheme: dark)").matches) {
			return "dark";
		}
		return "light";
	}
	if (preference === "light" || preference === "dark" || preference === "neon") return preference;
	return DEFAULT_THEME;
}

export function applyResolvedTheme(theme) {
	if (typeof document === "undefined") return;
	document.documentElement.setAttribute("data-theme", theme);
	document.documentElement.style.colorScheme = theme === "light" ? "light" : "dark";
}
