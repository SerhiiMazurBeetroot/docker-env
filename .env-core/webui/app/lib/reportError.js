export function reportError(entry) {
	const message = String(entry?.message || "").trim();
	if (!message) return;

	const payload = JSON.stringify({
		source: entry.source || "browser",
		action: entry.action || "",
		target: entry.target || "",
		message: message.slice(0, 500),
		detail: String(entry.detail || "").slice(0, 8000),
	});

	try {
		if (typeof navigator !== "undefined" && navigator.sendBeacon) {
			const blob = new Blob([payload], { type: "application/json" });
			if (navigator.sendBeacon("/api/diagnostics", blob)) return;
		}
	} catch {
		// fall through to fetch
	}

	fetch("/api/diagnostics", {
		method: "POST",
		headers: { "Content-Type": "application/json" },
		body: payload,
		keepalive: true,
	}).catch(() => {});
}
