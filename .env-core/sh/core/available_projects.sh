#!/bin/bash

# BASH_VERSION 3.2.57 (default macOS). No associative arrays.
# One row per project type. Keep every PROJECT_* array index-aligned.
# compose is the directory under the project root ("." is the root itself).
# container is the suffix of {DOMAIN_NAME}-<suffix>.
# also is extra container suffixes, space-separated.
# WIP rows appear in New project only when ENV_MODE=development.

PROJECT_IDS=(
	"wordpress"
	"bedrock"
	"php"
	"nextjs"
	"directus"
	"elasticsearch"
	"laravel"
	"directus_nextjs"
	"wordpress_nextjs"
	"nodejs"
	"nodejs_api"
)
PROJECT_MENU_TITLES=(
	"Wordpress"
	"BEDROCK"
	"PHP-Server"
	"Next.js"
	"Directus"
	"Elastic Stack"
	"Laravel [dev]"
	"Directus + Next.js [dev]"
	"WordPress + Next.js [dev]"
	"Node.js [dev]"
	"Node.js API [dev]"
)
PROJECT_SITE_LABELS=(
	"WordPress"
	"Bedrock"
	"PHP"
	"Next.js"
	"Directus"
	"Elastic"
	"Laravel"
	"Directus + Next.js"
	"WordPress + Next.js"
	"Node.js"
	"Node.js API"
)
PROJECT_TIERS=(
	"stable"
	"stable"
	"stable"
	"stable"
	"stable"
	"stable"
	"wip"
	"wip"
	"wip"
	"wip"
	"wip"
)
PROJECT_CREATE_FNS=(
	"docker_create_wp"
	"docker_create_bedrock"
	"docker_create_php"
	"docker_create_nextjs"
	"docker_create_directus"
	"docker_create_elastic"
	"docker_create_laravel"
	"docker_create_directus_nextjs"
	"docker_create_wp_next"
	"docker_create_nodejs"
	"docker_create_nodejs_api"
)
PROJECT_COMPOSE_DIRS=(
	"wp-docker"
	"docker"
	"docker"
	"docker"
	"docker"
	"docker"
	"docker"
	"docker"
	"docker"
	"."
	"docker"
)
PROJECT_CONTAINER_SUFFIXES=(
	"wordpress"
	"bedrock"
	"php"
	"nextjs"
	"directus"
	"elasticsearch"
	"laravel"
	"nextjs"
	"wordpress"
	"nodejs"
	"nodejs_api"
)
PROJECT_ALSO_CONTAINERS=(
	""
	""
	""
	""
	""
	""
	""
	"directus"
	"nextjs"
	""
	""
)
PROJECT_REQUIRE_NGINX=(
	"1"
	"1"
	"1"
	"1"
	"1"
	"1"
	"1"
	"1"
	"1"
	"1"
	"1"
)

_project_catalog_split() {
	local i

	STABLE_PROJECTS=()
	STABLE_PROJECT_TITLES=()
	WIP_PROJECTS=()
	WIP_PROJECT_TITLES=()

	for ((i = 0; i < ${#PROJECT_IDS[@]}; i++)); do
		if [[ "${PROJECT_TIERS[$i]}" == "wip" ]]; then
			WIP_PROJECTS+=("${PROJECT_IDS[$i]}")
			WIP_PROJECT_TITLES+=("${PROJECT_MENU_TITLES[$i]}")
		else
			STABLE_PROJECTS+=("${PROJECT_IDS[$i]}")
			STABLE_PROJECT_TITLES+=("${PROJECT_MENU_TITLES[$i]}")
		fi
	done

	ALL_PROJECT_TYPES=("${STABLE_PROJECTS[@]}" "${WIP_PROJECTS[@]}")
	ALL_PROJECT_TITLES=("${STABLE_PROJECT_TITLES[@]}" "${WIP_PROJECT_TITLES[@]}")
}

_project_catalog_split

# Extra rows on the site menu. Keep the four arrays index-aligned.
# One type may have several rows. "projects" is the old WordPress id.
# The command is a function name; the site menu calls it.
SITE_ACTION_TYPES=(
	"wordpress"
	"projects"
	"bedrock"
	"wordpress_nextjs"
	"wordpress_nextjs"
	"laravel"
	"nextjs"
	"directus"
	"directus_nextjs"
	"directus_nextjs"
	"php"
	"elasticsearch"
	"nodejs"
	"nodejs_api"
)
SITE_ACTION_LABELS=(
	"WordPress"
	"WordPress"
	"WordPress"
	"WordPress"
	"Next.js"
	"Laravel"
	"Next.js"
	"Directus"
	"Directus"
	"Next.js"
	"PHP"
	"Elastic"
	"Node.js"
	"Node.js API"
)
SITE_ACTION_HINTS=(
	"composer, multisite"
	"composer, multisite"
	"composer, multisite"
	"composer, multisite"
	"npm, logs"
	"artisan, migrate, composer"
	"npm, logs"
	"bootstrap, logs"
	"bootstrap, logs"
	"npm, logs"
	"composer, logs"
	"Kibana, health, logs"
	"npm, logs"
	"npm, health, logs"
)
SITE_ACTION_COMMANDS=(
	"wp_menu"
	"wp_menu"
	"wp_menu"
	"wp_menu"
	"nextjs_menu"
	"laravel_menu"
	"nextjs_menu"
	"directus_menu"
	"directus_menu"
	"nextjs_menu"
	"php_menu"
	"elastic_menu"
	"nodejs_menu"
	"nodejs_menu"
)

# Defaults for anything that still reads these names before the menu builds.
PROJECT_TITLES=("${STABLE_PROJECT_TITLES[@]}")
AVAILABLE_PROJECTS=("${STABLE_PROJECTS[@]}")

is_env_development() {
	[[ ${ENV_MODE:-} == "development" ]]
}

# "projects" is the old WordPress id.
project_index() {
	local type="${1:-}"
	local i

	[[ "$type" == "projects" ]] && type="wordpress"

	for ((i = 0; i < ${#PROJECT_IDS[@]}; i++)); do
		if [[ "${PROJECT_IDS[$i]}" == "$type" ]]; then
			printf '%s' "$i"
			return 0
		fi
	done

	return 1
}

project_field() {
	local field="${1:-}"
	local type="${2:-${PROJECT_TYPE:-}}"
	local i

	i=$(project_index "$type") || return 1

	case "$field" in
	menu) printf '%s' "${PROJECT_MENU_TITLES[$i]}" ;;
	label) printf '%s' "${PROJECT_SITE_LABELS[$i]}" ;;
	create) printf '%s' "${PROJECT_CREATE_FNS[$i]}" ;;
	compose) printf '%s' "${PROJECT_COMPOSE_DIRS[$i]}" ;;
	container) printf '%s' "${PROJECT_CONTAINER_SUFFIXES[$i]}" ;;
	also) printf '%s' "${PROJECT_ALSO_CONTAINERS[$i]}" ;;
	nginx) printf '%s' "${PROJECT_REQUIRE_NGINX[$i]}" ;;
	*) return 1 ;;
	esac
}

project_compose_dir() {
	local type="${1:-${PROJECT_TYPE:-}}"
	local rel

	rel=$(project_field compose "$type") || return 1

	if [[ "$rel" == "." ]]; then
		printf '%s' "${PROJECT_ROOT_DIR}"
	else
		printf '%s' "${PROJECT_ROOT_DIR}/${rel}"
	fi
}

project_container_name() {
	local type="${1:-${PROJECT_TYPE:-}}"
	local suffix

	suffix=$(project_field container "$type") || return 1
	printf '%s-%s' "${DOMAIN_NAME}" "$suffix"
}

# Uses the catalog nginx flag. Create functions call this instead of a private check.
project_require_nginx_for_type() {
	local type="${1:-${PROJECT_TYPE:-}}"
	local flag="1"

	flag=$(project_field nginx "$type") || flag="1"
	[[ "$flag" == "1" ]] || return 0
	docker_create_require_nginx
}

# Print "label<TAB>hint<TAB>command" for every extra action of this type.
site_actions_for_type() {
	local type="${1:-}"
	local i

	for ((i = 0; i < ${#SITE_ACTION_TYPES[@]}; i++)); do
		if [[ "${SITE_ACTION_TYPES[$i]}" == "$type" ]]; then
			printf '%s\t%s\t%s\n' \
				"${SITE_ACTION_LABELS[$i]}" \
				"${SITE_ACTION_HINTS[$i]}" \
				"${SITE_ACTION_COMMANDS[$i]}"
		fi
	done
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
	local fn=""

	load_project_modules

	# Next.js asks Docker vs local. Tests call the Docker create directly.
	if [[ "$type" == "nextjs" && ${TEST_RUNNING:-0} -ne 1 ]]; then
		fn="create_nextjs"
	else
		fn=$(project_field create "$type") || {
			ECHO_ERROR "Unsupported project type: ${type:-}"
			return 1
		}
	fi

	if ! declare -F "$fn" >/dev/null 2>&1; then
		ECHO_ERROR "Create function missing: $fn"
		return 1
	fi

	"$fn"
}
