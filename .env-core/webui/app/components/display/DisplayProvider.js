"use client";

import { createContext, useContext, useEffect, useMemo, useState } from "react";
import { readCardDensity, writeCardDensity, readExpandAll, writeExpandAll, readGroupByType, writeGroupByType, DISPLAY_OPTIONS } from "../../lib/display";

const DisplayContext = createContext({
	density: "comfortable",
	setDensity: () => {},
	expandAll: true,
	setExpandAll: () => {},
	groupByType: false,
	setGroupByType: () => {},
});

export function DisplayProvider({ children }) {
	const [density, setDensityState] = useState("comfortable");
	const [expandWide, setExpandWide] = useState(true);
	const [expandCompact, setExpandCompact] = useState(false);
	const [groupByType, setGroupByTypeState] = useState(false);

	useEffect(() => {
		setDensityState(readCardDensity());
		setExpandWide(readExpandAll("comfortable"));
		setExpandCompact(readExpandAll("compact"));
		setGroupByTypeState(readGroupByType());
	}, []);

	const expandAll = density === "compact" ? expandCompact : expandWide;

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
				if (density === "compact") setExpandCompact(resolved);
				else setExpandWide(resolved);
				writeExpandAll(resolved, density);
			},
			groupByType,
			setGroupByType: (next) => {
				const resolved = !!next;
				setGroupByTypeState(resolved);
				writeGroupByType(resolved);
			},
		}),
		[density, expandAll, groupByType]
	);

	return <DisplayContext.Provider value={value}>{children}</DisplayContext.Provider>;
}

export function useDisplay() {
	return useContext(DisplayContext);
}
