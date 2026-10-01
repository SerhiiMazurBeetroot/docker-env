#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

get_latest_wp_version() {
	local tag
	WP=()
	while IFS= read -r tag; do
		[[ -n "$tag" ]] && WP+=("$tag")
	done < <(curl -s 'https://api.github.com/repos/wordpress/wordpress/tags?per_page=2' | grep "name" | head -n 2 | awk '$0=$2' | grep -E '[0-9]+\.[0-9]+?' | tr -d '",')
	WP_LATEST_VER=$(echo "${WP[0]:-}" | grep -Eo '[0-9]+\.[0-9]+\.?[0-9]+' || echo "${WP[0]:-}.0")
	WP_PREV_VER=$(echo "${WP[1]:-}" | grep -Eo '[0-9]+\.[0-9]+\.?[0-9]+' || echo "${WP[1]:-}.0")
}
