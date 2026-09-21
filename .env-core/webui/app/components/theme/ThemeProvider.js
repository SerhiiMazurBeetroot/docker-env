"use client";

import { createContext, useContext, useEffect, useMemo, useState } from "react";
import {
	THEME_STORAGE_KEY,
	applyResolvedTheme,
	readThemePreference,
	resolvedTheme,
} from "../../lib/theme";

const ThemeContext = createContext({
	preference: "dark",
	theme: "dark",
	setPreference: () => {},
});

export function ThemeProvider({ children }) {
	const [preference, setPreferenceState] = useState("dark");
	const [theme, setTheme] = useState("dark");

	useEffect(() => {
		const next = readThemePreference();
		setPreferenceState(next);
		const resolved = resolvedTheme(next);
		setTheme(resolved);
		applyResolvedTheme(resolved);
	}, []);

	useEffect(() => {
		if (preference !== "auto") return undefined;
		const media = window.matchMedia("(prefers-color-scheme: dark)");
		const onChange = () => {
			const resolved = resolvedTheme("auto");
			setTheme(resolved);
			applyResolvedTheme(resolved);
		};
		media.addEventListener("change", onChange);
		return () => media.removeEventListener("change", onChange);
	}, [preference]);

	const value = useMemo(
		() => ({
			preference,
			theme,
			setPreference: (next) => {
				setPreferenceState(next);
				try {
					localStorage.setItem(THEME_STORAGE_KEY, next);
				} catch (err) {
					// ignore
				}
				const resolved = resolvedTheme(next);
				setTheme(resolved);
				applyResolvedTheme(resolved);
			},
		}),
		[preference, theme]
	);

	return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
	return useContext(ThemeContext);
}
