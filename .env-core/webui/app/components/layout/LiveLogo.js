"use client";

import { useId } from "react";

/*
 * The brand mark (same drawing as app/icon.svg), wired to live state:
 *  - the green stem is the system (Nginx and friends): green when every service runs,
 *    amber when some are down, red when all are down;
 *  - the three blue blocks light up in proportion to running sites (none lit = all stopped).
 *
 * Motion (keyframes in globals.css, all off under prefers-reduced-motion):
 *  - boot: the stem grows up, then the blocks slide out of it one by one;
 *  - healthy with sites running: a light pulse runs down the stem every few seconds and
 *    each lit block flashes as it passes, like a heartbeat handing out packets;
 *  - warn / down: the stem pulses amber (slow) or red (faster);
 *  - hover: the blocks slide out on their rails.
 * Boot, loop and hover sit on separate nested elements, so a state change swaps the loop
 * without replaying the boot.
 */

const ROWS = [
	{ y: 7, width: 8 },
	{ y: 13.5, width: 11.5 },
	{ y: 20, width: 8 },
];

const STEM = {
	ok: "#3ee0a2",
	idle: "#3ee0a2",
	warn: "#f5b14a",
	down: "#ff5c7a",
};

function systemState(system) {
	if (!system?.length) return "idle";
	const up = system.filter((item) => item.running).length;
	if (up === system.length) return "ok";
	return up === 0 ? "down" : "warn";
}

function litRows(projects) {
	if (!Array.isArray(projects) || projects.length === 0) return ROWS.length;
	const running = projects.filter((item) => item.running).length;
	if (running === 0) return 0;
	return Math.max(1, Math.round((running / projects.length) * ROWS.length));
}

export function liveLogoSummary(projects, system) {
	const parts = [];
	if (Array.isArray(projects)) {
		const running = projects.filter((item) => item.running).length;
		parts.push(`${running} of ${projects.length} sites running`);
	}
	if (system?.length) {
		const up = system.filter((item) => item.running).length;
		parts.push(up === system.length ? "system OK" : `${system.length - up} system service(s) down`);
	}
	return parts.join(" · ");
}

export default function LiveLogo({ projects, system, className = "h-8 w-8" }) {
	const state = systemState(system);
	const lit = litRows(projects);
	const anyRunning = Array.isArray(projects) && projects.some((item) => item.running);
	// The sidebar renders the logo twice (mobile + desktop), so clip/gradient ids must be unique.
	const uid = useId().replace(/[^a-zA-Z0-9_-]/g, "");
	const clipId = `live-logo-stem-${uid}`;
	const glowId = `live-logo-glow-${uid}`;

	return (
		<svg
			viewBox="0 0 32 32"
			fill="none"
			aria-hidden
			data-state={state}
			data-active={anyRunning ? "true" : "false"}
			className={`live-logo ${className}`}
		>
			<defs>
				<clipPath id={clipId}>
					<rect x="7" y="7" width="5" height="18" rx="2" />
				</clipPath>
				<linearGradient id={glowId} x1="0" y1="0" x2="0" y2="1">
					<stop offset="0" stopColor="#fff" stopOpacity="0" />
					<stop offset="0.5" stopColor="#fff" stopOpacity="0.75" />
					<stop offset="1" stopColor="#fff" stopOpacity="0" />
				</linearGradient>
			</defs>
			<rect width="32" height="32" rx="8" fill="#10151f" />

			<g className="live-logo-boot-stem">
				<rect className="live-logo-stem" x="7" y="7" width="5" height="18" rx="2" fill={STEM[state]} />
				<g clipPath={`url(#${clipId})`}>
					<rect className="live-logo-sweep" x="7" y="1" width="5" height="9" fill={`url(#${glowId})`} />
				</g>
			</g>

			{ROWS.map((row, index) => (
				<g
					key={row.y}
					className="live-logo-boot-row"
					style={{ "--d": `${260 + index * 110}ms` }}
				>
					<g className="live-logo-row" style={{ "--shift": `${1 + index * 0.6}px` }}>
						<rect
							className="live-logo-block"
							data-lit={index < lit ? "true" : "false"}
							style={{ "--p": `${index * 390}ms` }}
							x="13.5"
							y={row.y}
							width={row.width}
							height="5"
							rx="1.8"
							fill="#8aa4ff"
							fillOpacity={index < lit ? 1 : 0.18}
						/>
					</g>
				</g>
			))}
		</svg>
	);
}
