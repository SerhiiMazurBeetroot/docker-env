export const LOG_SETTINGS_KEY = "docker-env-log-settings";

export const LOG_FONT_SIZES = ["small", "medium", "large"];
export const LOG_DATE_FORMATS = [
	{ id: "auto", label: "Auto" },
	{ id: "MDY", label: "MM/DD/YYYY" },
	{ id: "DMY", label: "DD/MM/YYYY" },
	{ id: "DMYdot", label: "DD.MM.YYYY" },
	{ id: "ISO", label: "YYYY-MM-DD" },
];
export const LOG_TIME_FORMATS = [
	{ id: "auto", label: "Auto" },
	{ id: "12", label: "12" },
	{ id: "24", label: "24" },
];

export const DEFAULT_LOG_SETTINGS = {
	fontSize: "medium",
	compact: false,
	timestamps: true,
	wrap: true,
	highlightErrors: true,
	dateFormat: "auto",
	timeFormat: "auto",
};

export const PREVIEW_LOG_ENTRIES = [
	{
		ts: "2026-09-19T22:18:47.823Z",
		level: "info",
		message: "This is a preview of the logs",
		fields: [],
	},
	{
		ts: "2026-09-20T02:18:47.823Z",
		level: "warn",
		message: "A warning log looks like this",
		fields: [],
	},
	{
		ts: "2026-09-20T07:18:47.823Z",
		level: "error",
		message: "This is a multi line error message\nwith a second line\nand finally third line.",
		fields: [],
	},
	{
		ts: "2026-09-20T14:18:47.824Z",
		level: "info",
		message: "This is a complex log entry as json",
		fields: [
			{ key: "message", value: "This is a complex log entry as json" },
			{ key: "context.key", value: "value" },
			{ key: "context.key2", value: "value2" },
		],
	},
	{
		ts: "2026-09-20T14:18:47.824Z",
		level: "debug",
		message:
			"This is a very very long message which would wrap by default. Disabling soft wraps would disable this. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
		fields: [],
	},
];

export function readLogSettings() {
	try {
		const raw = localStorage.getItem(LOG_SETTINGS_KEY);
		if (!raw) return { ...DEFAULT_LOG_SETTINGS };
		const parsed = JSON.parse(raw);
		return {
			...DEFAULT_LOG_SETTINGS,
			...parsed,
			fontSize: LOG_FONT_SIZES.includes(parsed.fontSize) ? parsed.fontSize : DEFAULT_LOG_SETTINGS.fontSize,
			dateFormat: LOG_DATE_FORMATS.some((item) => item.id === parsed.dateFormat)
				? parsed.dateFormat
				: DEFAULT_LOG_SETTINGS.dateFormat,
			timeFormat: LOG_TIME_FORMATS.some((item) => item.id === parsed.timeFormat)
				? parsed.timeFormat
				: DEFAULT_LOG_SETTINGS.timeFormat,
		};
	} catch (err) {
		return { ...DEFAULT_LOG_SETTINGS };
	}
}

export function writeLogSettings(settings) {
	try {
		localStorage.setItem(LOG_SETTINGS_KEY, JSON.stringify(settings));
	} catch (err) {
		// ignore
	}
}
