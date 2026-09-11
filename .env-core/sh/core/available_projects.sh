#!/bin/bash

# BASH_VERSION 3.2.57 (default macOS)
# Keep each titles array index-aligned with its project ids.
# WIP types appear in New project only when ENV_MODE=development
# (local .env-core/data/settings.log, gitignored).

STABLE_PROJECT_TITLES=(
	"Wordpress"
	"BEDROCK"
	"PHP-Server"
	"Next.js"
	"Directus"
	"Elastic Stack"
)

STABLE_PROJECTS=(
	"wordpress"
	"bedrock"
	"php"
	"nextjs"
	"directus"
	"elasticsearch"
)

WIP_PROJECT_TITLES=(
	"Laravel [dev]"
	"Directus + Next.js [dev]"
	"Next.WP [dev]"
	"Node.js [dev]"
)

WIP_PROJECTS=(
	"laravel"
	"directus_nextjs"
	"wpnextjs"
	"nodejs"
)

# Full catalog: create dispatcher + docker name matching (existing WIP sites).
ALL_PROJECT_TYPES=("${STABLE_PROJECTS[@]}" "${WIP_PROJECTS[@]}")
ALL_PROJECT_TITLES=("${STABLE_PROJECT_TITLES[@]}" "${WIP_PROJECT_TITLES[@]}")

# Defaults for anything that still reads these names before the menu builds.
PROJECT_TITLES=("${STABLE_PROJECT_TITLES[@]}")
AVAILABLE_PROJECTS=("${STABLE_PROJECTS[@]}")

is_env_development() {
	[[ ${ENV_MODE:-} == "development" ]]
}

# Visible New-project list. Call after env_mode() (healthcheck).
build_visible_projects() {
	PROJECT_TITLES=("${STABLE_PROJECT_TITLES[@]}")
	AVAILABLE_PROJECTS=("${STABLE_PROJECTS[@]}")

	if is_env_development; then
		PROJECT_TITLES+=("${WIP_PROJECT_TITLES[@]}")
		AVAILABLE_PROJECTS+=("${WIP_PROJECTS[@]}")
	fi
}

create_project_by_type() {
	local type="${1:-${PROJECT_TYPE:-}}"

	load_project_modules

	case "${type:-}" in
	"wordpress")
		docker_create_wp
		;;
	"bedrock")
		docker_create_bedrock
		;;
	"php")
		docker_create_php
		;;
	"wpnextjs")
		docker_create_wp_next
		;;
	"nodejs")
		docker_create_nodejs
		;;
	"nextjs")
		# Tests skip the Docker vs local submenu.
		if [[ ${TEST_RUNNING:-0} -eq 1 ]]; then
			docker_create_nextjs
		else
			create_nextjs
		fi
		;;
	"directus")
		docker_create_directus
		;;
	"elasticsearch")
		docker_create_elastic
		;;
	"directus_nextjs")
		docker_create_directus_nextjs
		;;
	"laravel")
		docker_create_laravel
		;;
	*)
		ECHO_ERROR "Unsupported project type: ${type:-}"
		return 1
		;;
	esac
}
