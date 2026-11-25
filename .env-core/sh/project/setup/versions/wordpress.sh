#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

get_latest_wp_version() {
	local tag
	WP=()
	while IFS= read -r tag; do
		[[ -n "$tag" ]] && WP+=("$tag")
	done < <(curl -fs 'https://api.github.com/repos/wordpress/wordpress/tags?per_page=2' 2>/dev/null | grep "name" | head -n 2 | awk '$0=$2' | grep -E '[0-9]+\.[0-9]+?' | tr -d '",' || true)

	if [[ -z "${WP[0]:-}" ]]; then
		WP_LATEST_VER=""
		return 0
	fi

	WP_LATEST_VER=$(echo "${WP[0]}" | grep -Eo '[0-9]+\.[0-9]+\.?[0-9]+' || echo "${WP[0]}.0")
}
