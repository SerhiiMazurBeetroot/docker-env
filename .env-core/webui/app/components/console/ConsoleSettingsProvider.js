"use client";

import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { readConsoleAutoOpen, writeConsoleAutoOpen } from "../../lib/consoleSettings";

const ConsoleSettingsContext = createContext({
	autoOpen: true,
	setAutoOpen: () => {},
});

export function ConsoleSettingsProvider({ children }) {
	const [autoOpen, setAutoOpenState] = useState(true);

	useEffect(() => {
		setAutoOpenState(readConsoleAutoOpen());
	}, []);

	const value = useMemo(
		() => ({
			autoOpen,
			setAutoOpen: next => {
				const resolved = typeof next === "function" ? next(autoOpen) : next;
				setAutoOpenState(!!resolved);
				writeConsoleAutoOpen(!!resolved);
			},
		}),
		[autoOpen]
	);

	return <ConsoleSettingsContext.Provider value={value}>{children}</ConsoleSettingsContext.Provider>;
}

export function useConsoleSettings() {
	return useContext(ConsoleSettingsContext);
}
