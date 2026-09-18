#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Session / project context helpers (safe with set -o nounset).

has_domain_name() {
	[[ -n "${DOMAIN_NAME:-}" ]]
}

has_project_paths() {
	[[ -n "${PROJECT_DOCKER_DIR:-}" && -n "${DOCKER_CONTAINER_APP:-}" ]]
}

# Load DOMAIN_NAME + paths from instances.log when a domain is already known.
reload_project_context() {
	has_domain_name || return 1
	get_project_dir "skip_question"
}

# Pick a project (if needed) and ensure paths are loaded. Used by docker_* actions.
docker_require_project_context() {
	local action="${1:-======= Select project ========}"

	if ! has_domain_name; then
		get_existing_domains "$action"
	fi

	if ! has_domain_name; then
		ECHO_ERROR "No project selected"
		return 1
	fi

	if ! has_project_paths; then
		reload_project_context || return 1
	fi

	return 0
}

container_is_running() {
	local name="${1:-$DOCKER_CONTAINER_APP}"

	[[ -n "$name" ]] && docker ps --format '{{.Names}}' | grep -qE "(^|_|-)${name}($)"
}
