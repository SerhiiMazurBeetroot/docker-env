export function normalizeProjectDomain(value) {
	return String(value || "")
		.trim()
		.toLowerCase()
		.split(".")[0]
		.replace(/[\s_]+/g, "-")
		.replace(/[^a-z0-9-]+/g, "")
		.replace(/-+/g, "-")
		.replace(/^-+|-+$/g, "");
}
