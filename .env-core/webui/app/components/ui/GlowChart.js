"use client";

import { useId } from "react";

/*
 * Sparkline in the mplcyberpunk style: the line is drawn several times, wider and fainter
 * each time (glow), over an area that fades from the line colour to transparent (underglow).
 * `tone` is one of the chart tokens c1..c4 (or ok/accent/warn/danger), so it follows the theme.
 */
export default function GlowChart({ values = [], tone = "c1", height = 48, max, grid = false, className = "" }) {
	const id = useId().replace(/:/g, "");
	const width = 300;
	const points = values.length >= 2 ? values : values.length === 1 ? [values[0], values[0]] : [0, 0];
	const top = max ?? (Math.max(...points) * 1.2 || 1);
	const pad = 4;
	const x = (i) => (i / (points.length - 1)) * width;
	const y = (v) => height - pad - (Math.min(v, top) / top) * (height - pad * 2);
	const line = points.map((v, i) => `${i ? "L" : "M"}${x(i).toFixed(1)},${y(v).toFixed(1)}`).join(" ");
	const area = `${line} L${width},${height} L0,${height} Z`;
	const color = `rgb(var(--${tone}))`;
	const last = points.length - 1;

	return (
		<svg
			viewBox={`0 0 ${width} ${height}`}
			preserveAspectRatio="none"
			aria-hidden="true"
			className={`block w-full ${className}`}
			style={{ height }}
		>
			<defs>
				<linearGradient id={`fill-${id}`} x1="0" y1="0" x2="0" y2="1">
					<stop offset="0" stopColor={color} stopOpacity="0.3" />
					<stop offset="1" stopColor={color} stopOpacity="0" />
				</linearGradient>
			</defs>
			{grid
				? [0.25, 0.5, 0.75].map((f) => (
						<line key={f} x1="0" x2={width} y1={height * f} y2={height * f} stroke="var(--line)" strokeWidth="1" />
					))
				: null}
			<path d={area} fill={`url(#fill-${id})`} />
			{[10, 7, 4.5, 2.5].map((w, k) => (
				<path
					key={w}
					d={line}
					fill="none"
					stroke={color}
					strokeWidth={w}
					strokeOpacity={0.05 + k * 0.03}
					strokeLinejoin="round"
					strokeLinecap="round"
				/>
			))}
			<path
				d={line}
				fill="none"
				stroke={color}
				strokeWidth="1.6"
				strokeLinejoin="round"
				strokeLinecap="round"
				vectorEffect="non-scaling-stroke"
			/>
			<path
				d={`M${x(last).toFixed(1)},${y(points[last]).toFixed(1)} l0.01,0`}
				stroke={color}
				strokeWidth="6"
				strokeLinecap="round"
				vectorEffect="non-scaling-stroke"
			/>
		</svg>
	);
}
