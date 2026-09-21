"use client";

import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { DEFAULT_LOG_SETTINGS, readLogSettings, writeLogSettings } from "../../lib/logSettings";

const LogSettingsContext = createContext({
	settings: DEFAULT_LOG_SETTINGS,
	setSettings: () => {},
});

export function LogSettingsProvider({ children }) {
	const [settings, setSettingsState] = useState(DEFAULT_LOG_SETTINGS);

	useEffect(() => {
		setSettingsState(readLogSettings());
	}, []);

	const value = useMemo(
		() => ({
			settings,
			setSettings: (next) => {
				const resolved = typeof next === "function" ? next(settings) : next;
				setSettingsState(resolved);
				writeLogSettings(resolved);
			},
		}),
		[settings]
	);

	return <LogSettingsContext.Provider value={value}>{children}</LogSettingsContext.Provider>;
}

export function useLogSettings() {
	return useContext(LogSettingsContext);
}
