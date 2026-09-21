"use client";

import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { readCardDensity, writeCardDensity, readExpandAll, writeExpandAll, DISPLAY_OPTIONS } from "../../lib/display";

const DisplayContext = createContext({
	density: "comfortable",
	setDensity: () => {},
	expandAll: true,
	setExpandAll: () => {},
});

export function DisplayProvider({ children }) {
	const [density, setDensityState] = useState("comfortable");
	const [expandAll, setExpandAllState] = useState(true);

	useEffect(() => {
		setDensityState(readCardDensity());
		setExpandAllState(readExpandAll());
	}, []);

	const value = useMemo(
		() => ({
			density,
			setDensity: (next) => {
				const resolved = DISPLAY_OPTIONS.includes(next) ? next : "comfortable";
				setDensityState(resolved);
				writeCardDensity(resolved);
			},
			expandAll,
			setExpandAll: (next) => {
				const resolved = !!next;
				setExpandAllState(resolved);
				writeExpandAll(resolved);
			},
		}),
		[density, expandAll]
	);

	return <DisplayContext.Provider value={value}>{children}</DisplayContext.Provider>;
}

export function useDisplay() {
	return useContext(DisplayContext);
}
