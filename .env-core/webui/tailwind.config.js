/** @type {import('tailwindcss').Config} */
module.exports = {
	content: ["./app/**/*.{js,jsx}", "./lib/**/*.{js,jsx}"],
	theme: {
		extend: {
			colors: {
				ink: "rgb(var(--ink) / <alpha-value>)",
				panel: "rgb(var(--panel) / <alpha-value>)",
				raised: "rgb(var(--raised) / <alpha-value>)",
				line: "var(--line)",
				muted: "rgb(var(--muted) / <alpha-value>)",
				fg: "rgb(var(--fg) / <alpha-value>)",
				chip: "rgb(var(--chip) / <alpha-value>)",
				accent: "rgb(var(--accent) / <alpha-value>)",
				ok: "rgb(var(--ok) / <alpha-value>)",
				danger: "rgb(var(--danger) / <alpha-value>)",
				warn: "rgb(var(--warn) / <alpha-value>)",
			},
			boxShadow: {
				card: "0 18px 50px -24px rgba(0,0,0,0.35)",
				glow: "0 0 0 1px rgb(var(--accent) / 0.18), 0 12px 40px -16px rgb(var(--ok) / 0.25)",
			},
			fontFamily: {
				sans: ['"Plus Jakarta Sans"', "ui-sans-serif", "system-ui", "sans-serif"],
				mono: ['"JetBrains Mono"', "ui-monospace", "SFMono-Regular", "monospace"],
			},
			keyframes: {
				pulsedot: {
					"0%, 100%": { opacity: "1" },
					"50%": { opacity: "0.35" },
				},
			},
			animation: {
				pulsedot: "pulsedot 1.6s ease-in-out infinite",
			},
		},
	},
	plugins: [],
};
