"use client";

import { createContext, useContext, useEffect, useMemo, useState } from "react";
import {
	readConsoleAutoOpen,
	readConsoleAutoScroll,
	writeConsoleAutoOpen,
	writeConsoleAutoScroll,
} from "../../lib/consoleSettings";

const ConsoleSettingsContext = createContext({
	autoOpen: true,
	setAutoOpen: () => {},
	autoScroll: true,
	setAutoScroll: () => {},
});

export function ConsoleSettingsProvider({ children }) {
	const [autoOpen, setAutoOpenState] = useState(true);
	const [autoScroll, setAutoScrollState] = useState(true);

	useEffect(() => {
		setAutoOpenState(readConsoleAutoOpen());
		setAutoScrollState(readConsoleAutoScroll());
	}, []);

	const value = useMemo(
		() => ({
			autoOpen,
			setAutoOpen: next => {
				const resolved = typeof next === "function" ? next(autoOpen) : next;
				setAutoOpenState(!!resolved);
				writeConsoleAutoOpen(!!resolved);
			},
			autoScroll,
			setAutoScroll: next => {
				const resolved = typeof next === "function" ? next(autoScroll) : next;
				setAutoScrollState(!!resolved);
				writeConsoleAutoScroll(!!resolved);
			},
		}),
		[autoOpen, autoScroll]
	);

	return <ConsoleSettingsContext.Provider value={value}>{children}</ConsoleSettingsContext.Provider>;
}

export function useConsoleSettings() {
	return useContext(ConsoleSettingsContext);
}
