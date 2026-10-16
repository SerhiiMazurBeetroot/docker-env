#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Published releases offered by the Web UI and accepted as create presets.
# Empty means the live default from the version scripts.

version_catalog_file() {
	if [[ -n "${VERSION_CATALOG_FILE:-}" ]]; then
		printf '%s' "$VERSION_CATALOG_FILE"
		return 0
	fi
	printf '%s' "${ENV_DIR}/.env-core/data/catalog.json"
}

version_catalog_has() {
	local family="$1"
	local value="$2"
	local file

	[[ -n "$value" ]] || return 0
	file=$(version_catalog_file)
	[[ -f "$file" ]] || return 1
	jq -e --arg family "$family" --arg value "$value" \
		'(. [$family] // []) | index($value) != null' "$file" >/dev/null
}

version_catalog_wordpress_php() {
	local wp="$1"
	local php="$2"
	local file

	[[ -n "$wp" && -n "$php" ]] || return 0
	file=$(version_catalog_file)
	[[ -f "$file" ]] || return 1
	jq -e --arg wp "$wp" --arg php "$php" \
		'(.wordpressPhp[$wp] // []) | index($php) != null' "$file" >/dev/null
}

version_catalog_require() {
	local family="$1"
	local value="$2"
	local label="$3"

	[[ -n "$value" ]] || return 0
	if version_catalog_has "$family" "$value"; then
		return 0
	fi
	ECHO_ERROR "${label} ${value} is not a published version. Leave it empty for the default, or pick one from the list."
	return 1
}

version_catalog_reject_unknown() {
	version_catalog_require php "${PHP_VERSION:-}" "PHP" || return 1
	version_catalog_require wordpress "${WP_VERSION:-}" "WordPress" || return 1
	version_catalog_require laravel "${LARAVEL_VERSION:-}" "Laravel" || return 1
	version_catalog_require node "${NODE_VERSION:-}" "Node.js" || return 1
	version_catalog_require nextjs "${NEXTJS_VERSION:-}" "Next.js" || return 1
	version_catalog_require directus "${DIRECTUS_VERSION:-}" "Directus" || return 1
	version_catalog_require elasticsearch "${ELASTIC_VERSION:-}" "Elasticsearch" || return 1

	if [[ -n "${WP_VERSION:-}" && -n "${PHP_VERSION:-}" ]]; then
		if ! version_catalog_wordpress_php "${WP_VERSION}" "${PHP_VERSION}"; then
			ECHO_ERROR "WordPress ${WP_VERSION} has no published image for PHP ${PHP_VERSION}."
			return 1
		fi
	fi
}
