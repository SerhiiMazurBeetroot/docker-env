const OPTION_FAMILIES = {
	PHP_VERSION: "php",
	WP_VERSION: "wordpress",
	LARAVEL_VERSION: "laravel",
	NODE_VERSION: "node",
	NEXTJS_VERSION: "nextjs",
	DIRECTUS_VERSION: "directus",
	ELASTIC_VERSION: "elasticsearch",
};

const OPTION_LABELS = {
	PHP_VERSION: "PHP",
	WP_VERSION: "WordPress",
	LARAVEL_VERSION: "Laravel",
	NODE_VERSION: "Node.js",
	NEXTJS_VERSION: "Next.js",
	DIRECTUS_VERSION: "Directus",
	ELASTIC_VERSION: "Elasticsearch",
};

export function versionsForOption(catalog, key, selected = {}) {
	const family = OPTION_FAMILIES[key];
	if (!family) return [];
	const list = Array.isArray(catalog?.[family]) ? catalog[family] : [];
	if (key === "PHP_VERSION" && selected.WP_VERSION) {
		const allowed = catalog?.wordpressPhp?.[selected.WP_VERSION];
		if (Array.isArray(allowed)) {
			const known = new Set(allowed);
			return list.filter((item) => known.has(item));
		}
	}
	return list;
}

export function versionChoiceError(options, catalog) {
	const chosen = options || {};
	for (const [key, value] of Object.entries(chosen)) {
		if (!value || !OPTION_FAMILIES[key]) continue;
		const list = catalog?.[OPTION_FAMILIES[key]];
		if (!Array.isArray(list) || !list.includes(String(value))) {
			return `${OPTION_LABELS[key]} ${value} is not a published version. Leave it empty for the default, or pick one from the list.`;
		}
	}

	const wp = chosen.WP_VERSION;
	const php = chosen.PHP_VERSION;
	if (wp && php) {
		const allowed = catalog?.wordpressPhp?.[wp];
		if (!Array.isArray(allowed) || !allowed.includes(String(php))) {
			return `WordPress ${wp} has no published image for PHP ${php}.`;
		}
	}
	return null;
}
