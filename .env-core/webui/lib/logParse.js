const TS_RE =
	/^(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:?\d{2})?)\s(.*)$/;

const LEVEL_RULES = [
	["error", /\b(error|err|fatal|crit|critical|panic|exception|emerg)\b/i],
	["warn", /\b(warn|warning)\b/i],
	["debug", /\b(debug|trace)\b/i],
	["info", /\b(info|notice)\b/i],
];

function pad(value) {
	return String(value).padStart(2, "0");
}

export function detectLevel(message, json) {
	const fromJson = String(json?.level || json?.severity || json?.loglevel || "").toLowerCase();
	if (fromJson.startsWith("err") || fromJson === "fatal" || fromJson === "crit") return "error";
	if (fromJson.startsWith("warn")) return "warn";
	if (fromJson === "debug" || fromJson === "trace") return "debug";
	if (fromJson === "info" || fromJson === "notice") return "info";

	const text = String(message || "");
	for (const [level, rule] of LEVEL_RULES) {
		if (rule.test(text)) return level;
	}
	return "info";
}

export function parseJsonMessage(message) {
	const text = String(message || "").trim();
	if (!text.startsWith("{") || !text.endsWith("}")) return null;
	try {
		const value = JSON.parse(text);
		return value && typeof value === "object" && !Array.isArray(value) ? value : null;
	} catch (err) {
		return null;
	}
}

export function flattenJson(value, prefix = "", acc = []) {
	if (value == null) return acc;
	if (typeof value !== "object") {
		acc.push({ key: prefix || "value", value: String(value) });
		return acc;
	}
	for (const [key, item] of Object.entries(value)) {
		const next = prefix ? `${prefix}.${key}` : key;
		if (item && typeof item === "object" && !Array.isArray(item)) {
			flattenJson(item, next, acc);
		} else {
			acc.push({ key: next, value: Array.isArray(item) ? JSON.stringify(item) : String(item) });
		}
	}
	return acc;
}

export function parseDockerLogLine(line) {
	const raw = String(line || "").replace(/\u0000/g, "");
	if (!raw) return null;
	const match = raw.match(TS_RE);
	const ts = match ? match[1] : "";
	const message = match ? match[2] : raw;
	const json = parseJsonMessage(message);
	const display = json && (json.message || json.msg || json.log) ? String(json.message || json.msg || json.log) : message;
	return {
		ts,
		message: display,
		raw: message,
		level: detectLevel(display, json),
		fields: json ? flattenJson(json).filter((item) => !["level", "severity", "loglevel", "time", "ts", "timestamp"].includes(item.key)) : [],
	};
}

export function formatLogDate(date, format) {
	if (!(date instanceof Date) || Number.isNaN(date.getTime())) return "";
	if (format === "auto") {
		return date.toLocaleDateString(undefined, { year: "numeric", month: "2-digit", day: "2-digit" });
	}
	const yyyy = date.getFullYear();
	const mm = pad(date.getMonth() + 1);
	const dd = pad(date.getDate());
	if (format === "DMY") return `${dd}/${mm}/${yyyy}`;
	if (format === "DMYdot") return `${dd}.${mm}.${yyyy}`;
	if (format === "ISO") return `${yyyy}-${mm}-${dd}`;
	return `${mm}/${dd}/${yyyy}`;
}

export function formatLogClock(date, format) {
	if (!(date instanceof Date) || Number.isNaN(date.getTime())) return "";
	if (format === "auto") {
		return date.toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit", second: "2-digit" });
	}
	if (format === "24") {
		return `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`;
	}
	const hours = date.getHours();
	const suffix = hours >= 12 ? "PM" : "AM";
	const hour12 = hours % 12 || 12;
	return `${pad(hour12)}:${pad(date.getMinutes())}:${pad(date.getSeconds())} ${suffix}`;
}
