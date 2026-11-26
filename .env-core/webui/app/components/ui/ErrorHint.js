"use client";

import { useEffect, useId, useRef, useState } from "react";
import { IconWarn } from "./Icons";

/*
 * A small red warning icon that reveals the last failure on hover or keyboard focus.
 * A click pins it open (touch screens have no hover); Escape or a click elsewhere closes it.
 * Keeps the card height steady instead of a red box that grows with the message.
 */
export default function ErrorHint({ label, message }) {
	const [pinned, setPinned] = useState(false);
	const root = useRef(null);
	const tipId = useId();

	useEffect(() => {
		if (!pinned) return undefined;
		function onPointer(event) {
			if (!root.current?.contains(event.target)) setPinned(false);
		}
		function onKey(event) {
			if (event.key === "Escape") setPinned(false);
		}
		window.addEventListener("pointerdown", onPointer);
		window.addEventListener("keydown", onKey);
		return () => {
			window.removeEventListener("pointerdown", onPointer);
			window.removeEventListener("keydown", onKey);
		};
	}, [pinned]);

	if (!message) return null;

	return (
		<span ref={root} className="group/err relative inline-flex shrink-0">
			<button
				type="button"
				onClick={() => setPinned((value) => !value)}
				aria-label={`${label}: ${message}`}
				aria-describedby={tipId}
				aria-expanded={pinned}
				className="inline-flex h-5 w-5 items-center justify-center rounded-md text-danger hover:bg-danger/15 focus-visible:bg-danger/15 focus-visible:outline-none"
			>
				<IconWarn />
			</button>
			<span
				id={tipId}
				role="tooltip"
				className={`absolute left-0 top-full z-30 mt-1.5 w-max max-w-[min(20rem,80vw)] whitespace-pre-wrap break-words rounded-lg border border-danger/40 bg-panel px-3 py-2 text-left text-[12px] font-normal normal-case leading-snug text-fg shadow-card transition ${
					pinned
						? "visible opacity-100"
						: "invisible opacity-0 group-focus-within/err:visible group-focus-within/err:opacity-100 group-hover/err:visible group-hover/err:opacity-100"
				}`}
			>
				<span className="mb-0.5 block font-semibold text-danger">{label}</span>
				{message}
			</span>
		</span>
	);
}
