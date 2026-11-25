#!/bin/bash

# BASH_VERSION 3.2.57 (default macOS). No associative arrays, so every PROJECT_*
# array is one column of the same table. Row 0 is wordpress in every array.
#
# Add a project type:
#   1. Append its id to PROJECT_IDS.
#   2. Append one value to every other PROJECT_* array, in that same position.
#   3. Read a cell with: project_field <field> <id>
#      fields: id menu label compose container also nginx flow setup_args
#              dir_question flags after
#
# WIP rows (PROJECT_TIERS=wip) show in New project only when ENV_MODE=development.
# docker_create_dispatch is the only create entry. It reads flow, setup_args,
# dir_question, flags, and after.

# Type id. The index of an id is the row number for every array below.
# "projects" is accepted by project_index as an alias of wordpress.
PROJECT_IDS=(
	"wordpress"          # 0
	"bedrock"            # 1
	"php"                # 2
	"nextjs"             # 3
	"directus"           # 4
	"elasticsearch"      # 5
	"laravel"            # 6  wip
	"directus_nextjs"    # 7  wip
	"wordpress_nextjs"   # 8  wip
	"nodejs_api"         # 9  wip
)
# Label in New site and the Web UI create list. project_field menu.
# build_visible_projects copies these into PROJECT_TITLES.
PROJECT_MENU_TITLES=(
	"Wordpress"                    # wordpress
	"BEDROCK"                      # bedrock
	"PHP-Server"                   # php
	"Next.js"                      # nextjs
	"Directus"                     # directus
	"Elastic Stack"                # elasticsearch
	"Laravel [dev]"                # laravel
	"Directus + Next.js [dev]"     # directus_nextjs
	"WordPress + Next.js [dev]"    # wordpress_nextjs
	"Node.js API [dev]"            # nodejs_api
)
# Short name in the open-site header: "domain · label · running".
# project_field label. site_menu.sh prints it.
PROJECT_SITE_LABELS=(
	"WordPress"              # wordpress
	"Bedrock"                # bedrock
	"PHP"                    # php
	"Next.js"                # nextjs
	"Directus"               # directus
	"Elastic"                # elasticsearch
	"Laravel"                # laravel
	"Directus + Next.js"     # directus_nextjs
	"WordPress + Next.js"    # wordpress_nextjs
	"Node.js API"            # nodejs_api
)
# stable = always listed. wip = listed only when ENV_MODE=development.
# _project_catalog_split fills STABLE_PROJECTS and WIP_PROJECTS from this.
PROJECT_TIERS=(
	"stable"    # wordpress
	"stable"    # bedrock
	"stable"    # php
	"stable"    # nextjs
	"stable"    # directus
	"stable"    # elasticsearch
	"wip"       # laravel
	"wip"       # directus_nextjs
	"wip"       # wordpress_nextjs
	"wip"       # nodejs_api
)
# How docker_create_dispatch asks for the domain and the project args.
#   installation_type  setup_installation_type_callback asks default / custom /
#                      beetroot, then resolves the directory and the args.
#   domain             get_domain_name, then get_project_dir and set_project_args.
PROJECT_SETUP_FLOWS=(
	"installation_type"    # wordpress
	"installation_type"    # bedrock
	"domain"               # php
	"domain"               # nextjs
	"domain"               # directus
	"domain"               # elasticsearch
	"domain"               # laravel
	"domain"               # directus_nextjs
	"domain"               # wordpress_nextjs
	"domain"               # nodejs_api
)
# 1 = domain flow calls set_project_args (versions, db name, …).
# 0 = skip that call. installation_type ignores this and asks inside its own menu.
PROJECT_SETUP_ARGS=(
	"0"    # wordpress — args come from the install-type menu
	"0"    # bedrock — same
	"1"    # php
	"1"    # nextjs
	"1"    # directus
	"1"    # elasticsearch
	"1"    # laravel
	"1"    # directus_nextjs
	"1"    # wordpress_nextjs
	"1"    # nodejs_api
)
# Passed to get_project_dir in the domain flow. installation_type ignores it.
# "" asks for the host. "skip_question" keeps the default host.
PROJECT_DIR_QUESTIONS=(
	""                 # wordpress
	""                 # bedrock
	""                 # php
	""                 # nextjs
	""                 # directus
	""                 # elasticsearch
	""                 # laravel
	""                 # directus_nextjs
	""                 # wordpress_nextjs
	""                 # nodejs_api
)
# Space-separated KEY=VALUE flags. docker_create_dispatch exports them before
# docker_create_project. A value cannot contain a space. Empty uses the defaults
# in docker_create.sh (fix permissions, reload Nginx). The template always comes
# from docker-env-template-<id> on GitHub, or a local copy with
# CREATE_TEMPLATE_SOURCE=local (docker_create_template_check).
#   CREATE_SYNC_PORT_FRONT=1   publish the app on the same host port as the proxy
#   CREATE_SKIP_PERMISSIONS=1  do not chown the project tree after start
#   CREATE_SKIP_DOCKER_RESTART=1  do not reload Nginx; the after hook may do it
PROJECT_CREATE_FLAGS=(
	""    # wordpress
	"CREATE_SKIP_DOCKER_RESTART=1 CREATE_SKIP_PERMISSIONS=1"    # bedrock
	""    # php
	"CREATE_SYNC_PORT_FRONT=1"    # nextjs
	""    # directus
	"CREATE_SKIP_DOCKER_RESTART=1"    # elasticsearch — after hook reloads Nginx
	""    # laravel
	""    # directus_nextjs
	""    # wordpress_nextjs
	"CREATE_SKIP_PERMISSIONS=1"    # nodejs_api
)
# Function called after the containers are up. Define it in
# sh/project/docker/docker_create/docker_create_<id>.sh. Empty runs nothing.
PROJECT_AFTER_HOOKS=(
	"docker_create_wp_after"                 # wordpress — install WordPress
	"docker_create_bedrock_after"            # bedrock
	""                                       # php
	"docker_create_nextjs_after"             # nextjs
	""                                       # directus
	"docker_create_elastic_after"            # elasticsearch
	"docker_create_laravel_after"            # laravel
	"docker_create_directus_nextjs_after"    # directus_nextjs
	"docker_create_wp_next_after"            # wordpress_nextjs
	""                                       # nodejs_api
)
# Directory of docker-compose.yml under the project root.
# "." means the compose file is the project root itself.
# project_compose_dir joins this with PROJECT_ROOT_DIR. project_field compose.
PROJECT_COMPOSE_DIRS=(
	"wp-docker"    # wordpress
	"docker"       # bedrock
	"docker"       # php
	"docker"       # nextjs
	"docker"       # directus
	"docker"       # elasticsearch
	"docker"       # laravel
	"docker"       # directus_nextjs
	"docker"       # wordpress_nextjs
	"docker"       # nodejs_api
)
# Main container is {DOMAIN_NAME}-<suffix>. project_container_name.
# Used by the site menu and the tests to find the app container.
PROJECT_CONTAINER_SUFFIXES=(
	"wordpress"        # wordpress → blog-wordpress
	"bedrock"          # bedrock
	"php"              # php
	"nextjs"           # nextjs
	"directus"         # directus
	"elasticsearch"    # elasticsearch
	"laravel"          # laravel
	"nextjs"           # directus_nextjs — the Next.js app is the main container
	"wordpress"        # wordpress_nextjs — WordPress is the main container
	"nodejs_api"       # nodejs_api
)
# Extra container suffixes on the same project, space-separated.
# tests_helpers.sh checks these in addition to the main suffix. Empty if none.
PROJECT_ALSO_CONTAINERS=(
	""            # wordpress
	""            # bedrock
	""            # php
	""            # nextjs
	""            # directus
	""            # elasticsearch
	""            # laravel
	"directus"    # directus_nextjs → also {domain}-directus
	"nextjs"      # wordpress_nextjs → also {domain}-nextjs
	""            # nodejs_api
)
# 1 = create refuses to start unless the Nginx proxy is running
# (project_require_nginx_for_type → docker_create_require_nginx). 0 = skip that check.
PROJECT_REQUIRE_NGINX=(
	"1"    # wordpress
	"1"    # bedrock
	"1"    # php
	"1"    # nextjs
	"1"    # directus
	"1"    # elasticsearch
	"1"    # laravel
	"1"    # directus_nextjs
	"1"    # wordpress_nextjs
	"1"    # nodejs_api
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
}

_project_catalog_split

# Extra rows on the open-site menu, after Open / Start / Shell / Database.
# These four arrays share their own index. They are not aligned with PROJECT_IDS:
# one project type can have several rows (a combined site shows each half).
# site_actions_for_type prints "label<TAB>hint<TAB>command" for the current type.
# site_menu.sh calls the command, which must be a function name.
# To add a tool, append one line to all four arrays. TYPE must be a PROJECT_IDS
# value, or "projects" (the old wordpress id).
SITE_ACTION_TYPES=(
	"wordpress"            # → wp_menu
	"projects"             # old wordpress id → wp_menu
	"bedrock"              # → wp_menu
	"wordpress_nextjs"     # WordPress half → wp_menu
	"wordpress_nextjs"     # Next.js half → nextjs_menu
	"laravel"              # → laravel_menu
	"nextjs"               # → nextjs_menu
	"directus"             # → directus_menu
	"directus_nextjs"      # Directus half → directus_menu
	"directus_nextjs"      # Next.js half → nextjs_menu
	"php"                  # → php_menu
	"elasticsearch"        # → elastic_menu
	"nodejs_api"           # → nodejs_menu
)
SITE_ACTION_LABELS=(
	"WordPress"       # wordpress
	"WordPress"       # projects
	"WordPress"       # bedrock
	"WordPress"       # wordpress_nextjs
	"Next.js"         # wordpress_nextjs
	"Laravel"         # laravel
	"Next.js"         # nextjs
	"Directus"        # directus
	"Directus"        # directus_nextjs
	"Next.js"         # directus_nextjs
	"PHP"             # php
	"Elastic"         # elasticsearch
	"Node.js API"     # nodejs_api
)
# Grey hint under the menu row. Shown by site_menu_row.
SITE_ACTION_HINTS=(
	"composer, multisite"            # wordpress
	"composer, multisite"            # projects
	"composer, multisite"            # bedrock
	"composer, multisite"            # wordpress_nextjs / WordPress
	"npm, logs"                      # wordpress_nextjs / Next.js
	"artisan, migrate, composer"     # laravel
	"npm, logs"                      # nextjs
	"bootstrap, logs"                # directus
	"bootstrap, logs"                # directus_nextjs / Directus
	"npm, logs"                      # directus_nextjs / Next.js
	"composer, logs"                 # php
	"Kibana, health, logs"           # elasticsearch
	"npm, health, logs"              # nodejs_api
)
# Function the site menu calls for that row. Defined in sh/menus/*_menu.sh.
SITE_ACTION_COMMANDS=(
	"wp_menu"          # wordpress
	"wp_menu"          # projects
	"wp_menu"          # bedrock
	"wp_menu"          # wordpress_nextjs / WordPress
	"nextjs_menu"      # wordpress_nextjs / Next.js
	"laravel_menu"     # laravel
	"nextjs_menu"      # nextjs
	"directus_menu"    # directus
	"directus_menu"    # directus_nextjs / Directus
	"nextjs_menu"      # directus_nextjs / Next.js
	"php_menu"         # php
	"elastic_menu"     # elasticsearch
	"nodejs_menu"      # nodejs_api
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
	id) printf '%s' "${PROJECT_IDS[$i]}" ;;
	menu) printf '%s' "${PROJECT_MENU_TITLES[$i]}" ;;
	label) printf '%s' "${PROJECT_SITE_LABELS[$i]}" ;;
	compose) printf '%s' "${PROJECT_COMPOSE_DIRS[$i]}" ;;
	container) printf '%s' "${PROJECT_CONTAINER_SUFFIXES[$i]}" ;;
	also) printf '%s' "${PROJECT_ALSO_CONTAINERS[$i]}" ;;
	nginx) printf '%s' "${PROJECT_REQUIRE_NGINX[$i]}" ;;
	flow) printf '%s' "${PROJECT_SETUP_FLOWS[$i]}" ;;
	setup_args) printf '%s' "${PROJECT_SETUP_ARGS[$i]}" ;;
	dir_question) printf '%s' "${PROJECT_DIR_QUESTIONS[$i]}" ;;
	flags) printf '%s' "${PROJECT_CREATE_FLAGS[$i]}" ;;
	after) printf '%s' "${PROJECT_AFTER_HOOKS[$i]}" ;;
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

# JSON for CLI/Web UI: visible types and catalog metadata (compose dir, tier).
project_catalog_emit_json() {
	local i id idx title compose tier json="[]"

	build_visible_projects

	for ((i = 0; i < ${#AVAILABLE_PROJECTS[@]}; i++)); do
		id="${AVAILABLE_PROJECTS[$i]}"
		title="${PROJECT_TITLES[$i]}"
		idx=$(project_index "$id") || continue
		compose="${PROJECT_COMPOSE_DIRS[$idx]}"
		tier="${PROJECT_TIERS[$idx]}"

		json=$(jq -nc --argjson acc "$json" --arg id "$id" --arg title "$title" --arg compose "$compose" --arg tier "$tier" \
			'$acc + [{id:$id,title:$title,compose:$compose,tier:$tier}]')
	done

	jq -nc \
		--argjson types "$json" \
		--arg mode "${ENV_MODE:-}" \
		--arg core "${CORE_VERSION:-}" \
		'{ok:true,types:$types,mode:$mode,coreVersion:$core}'
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

	# Next.js asks Docker vs local. Tests and the CLI call the Docker create directly.
	if [[ "$type" == "nextjs" && ${TEST_RUNNING:-0} -ne 1 && ${CLI_NONINTERACTIVE:-0} -ne 1 ]]; then
		create_nextjs
		return
	fi

	docker_create_dispatch "$type"
}
