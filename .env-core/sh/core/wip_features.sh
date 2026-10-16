#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# WIP feature gate. Ids live in wip_features.ids (one per line).
# wip_feature <id> succeeds only for a registered id while ENV_MODE=development.

wip_features_file() {
	printf '%s' "${ENV_DIR}/.env-core/sh/core/wip_features.ids"
}

wip_feature_registered() {
	local id="${1:-}"
	local line file

	[[ -n "$id" ]] || return 1
	file=$(wip_features_file)
	[[ -f "$file" ]] || return 1

	while IFS= read -r line || [[ -n "$line" ]]; do
		line="${line%%#*}"
		line="${line#"${line%%[![:space:]]*}"}"
		line="${line%"${line##*[![:space:]]}"}"
		[[ -z "$line" ]] && continue
		[[ "$line" == "$id" ]] && return 0
	done <"$file"

	return 1
}

wip_feature() {
	wip_feature_registered "${1:-}" || return 1
	is_env_development
}
