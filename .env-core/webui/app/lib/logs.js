export const CONSOLE_OPEN_KEY = "docker-env-console-open";

export function readConsoleOpen() {
	try {
		return localStorage.getItem(CONSOLE_OPEN_KEY) === "1";
	} catch (err) {
		return false;
	}
}

export function writeConsoleOpen(open) {
	try {
		localStorage.setItem(CONSOLE_OPEN_KEY, open ? "1" : "0");
	} catch (err) {
		// ignore
	}
}

export function stripAnsi(text) {
	return String(text || "").replace(/\u001b\[[0-9;]*m/g, "");
}

export function visibleLog(text) {
	return stripAnsi(text)
		.replace(/^[ \t]*WEBUI_URLS_JSON:.*$/gm, "")
		.replace(/WEBUI_URLS_JSON:\[[^\]]*$/g, "");
}

export function appendCliLog(prev, chunk) {
	return visibleLog(`${prev}${chunk}`)
		.split("\n")
		.map((line) => line.split("\r").pop())
		.join("\n");
}

export function linkify(text) {
	const escaped = stripAnsi(text)
		.replace(/&/g, "&amp;")
		.replace(/</g, "&lt;")
		.replace(/>/g, "&gt;");
	return escaped.replace(
		/(https?:\/\/[^\s<&]+)/g,
		'<a href="$1" target="_blank" rel="noreferrer">$1</a>'
	);
}

export async function readSse(response, onEvent) {
	const reader = response.body.getReader();
	const decoder = new TextDecoder();
	let buffer = "";

	while (true) {
		const { done, value } = await reader.read();
		if (done) break;
		buffer += decoder.decode(value, { stream: true });
		let idx;
		while ((idx = buffer.indexOf("\n\n")) !== -1) {
			const raw = buffer.slice(0, idx);
			buffer = buffer.slice(idx + 2);
			for (const line of raw.split("\n")) {
				if (!line.startsWith("data:")) continue;
				const payload = line.replace(/^data:\s?/, "");
				if (!payload) continue;
				onEvent(JSON.parse(payload));
			}
		}
	}
}
