#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_require_nginx() {
	if [[ ${NGINX_EXISTS:-0} -ne 1 ]]; then
		ECHO_ERROR "Nginx container not running"
		return 1
	fi
}

# Compose failed after the tree, catalog row, and maybe some containers exist.
# Hosts are removed too when a line was already written.
docker_create_rollback() {
	local compose_dir="${CREATE_COMPOSE_DIR:-${PROJECT_DOCKER_DIR:-}}"

	ECHO_ERROR "Create failed. Removing the partial site [${DOMAIN_NAME:-}]."

	if [[ -n "$compose_dir" && -f "$compose_dir/docker-compose.yml" ]]; then
		docker_compose_runner "down -v --remove-orphans" "$compose_dir" || true
	fi

	INSTANCES_STATUS="remove"
	delete_site_data || true
}

docker_create_require_new_site() {
	if [[ ${DOMAIN_EXISTS:-0} != 0 ]]; then
		echo_site_exists
		return 1
	fi
}

# Local template for TYPE: the sibling checkout first, then the copy bundled
# in this repo. A folder counts only when it has at least one file.
docker_create_local_template_dir() {
	local type="${1:-${PROJECT_TYPE:-}}" dir
	for dir in \
		"$ENV_DIR/../docker-env-templates/docker-env-template-${type}" \
		"$ENV_DIR/.env-core/templates/${type}"; do
		if [[ -d "$dir" ]] && [[ -n "$(find "$dir" -type f -not -path '*/.git/*' -print -quit 2>/dev/null)" ]]; then
			printf '%s' "$dir"
			return 0
		fi
	done
	return 1
}

docker_create_template_url() {
	printf '%s-%s.git' "${TEMPLATES_REPO:-}" "${1:-${PROJECT_TYPE:-}}"
}

# Runs before any question, so a type without a template fails at once
# instead of after the domain and versions were asked.
#   CREATE_TEMPLATE_SOURCE=github (default)  the GitHub repo must answer.
#   CREATE_TEMPLATE_SOURCE=local             a local template must exist.
docker_create_template_check() {
	local type="${1:-${PROJECT_TYPE:-}}" url

	if [[ ${CREATE_TEMPLATE_SOURCE:-github} == "local" ]]; then
		if docker_create_local_template_dir "$type" >/dev/null; then
			return 0
		fi
		ECHO_ERROR "No local template for ${type}."
		ECHO_INFO "Looked in ../docker-env-templates/docker-env-template-${type} and .env-core/templates/${type}."
		return 1
	fi

	if ! command -v git >/dev/null 2>&1; then
		ECHO_ERROR "git is not installed"
		return 1
	fi

	url=$(docker_create_template_url "$type")
	if ! GIT_TERMINAL_PROMPT=0 git ls-remote --exit-code "$url" HEAD >/dev/null 2>&1; then
		ECHO_ERROR "Template repository for ${type} is not reachable: ${url}"
		ECHO_INFO "Check the network, or set CREATE_TEMPLATE_SOURCE=local to copy a local template."
		return 1
	fi
}

docker_create_copy_local_template() {
	local src

	src=$(docker_create_local_template_dir "${PROJECT_TYPE:-}") || {
		ECHO_ERROR "Local template not found for ${PROJECT_TYPE:-}"
		return 1
	}

	ECHO_INFO "Using local template ${src}"
	rsync -a --exclude .git "$src/" "$PROJECT_ROOT_DIR/"
}

docker_create_clone_template() {
	local url
	url=$(docker_create_template_url "${PROJECT_TYPE:-}")
	GIT_TERMINAL_PROMPT=0 git clone --depth 1 "$url" "$PROJECT_ROOT_DIR"
}

# Optional flags (unset at end of docker_create_project). docker_create_dispatch
# sets these from PROJECT_CREATE_FLAGS in core/available_projects.sh:
#   CREATE_TEMPLATE_SOURCE=github|local
#     github is the default and clones docker-env-template-$PROJECT_TYPE.
#     local copies the sibling checkout, or .env-core/templates/$PROJECT_TYPE.
#     docker_create_template_check verifies the source before any question.
#   CREATE_COMPOSE_CMD="up -d"
#   CREATE_COMPOSE_DIR=
#   CREATE_ENV_FILE=
#   CREATE_SYNC_PORT_FRONT=1
#   CREATE_SKIP_PERMISSIONS=1
#   CREATE_SKIP_DOCKER_RESTART=1
docker_create_project() {
	local after_up="${1:-}"
	local notice_mode="${2:-open}"

	ECHO_INFO "Setting up Docker containers for $DOMAIN_FULL"

	get_all_ports
	if [[ ${CREATE_SYNC_PORT_FRONT:-0} -eq 1 ]]; then
		export PORT_FRONT=$PORT
	fi

	get_project_dir "skip_question"
	print_to_file_instances "building"
	mkdir -p "$PROJECT_ROOT_DIR"

	# github | local. Export CREATE_TEMPLATE_SOURCE=local to skip the clone.
	local template_source="github"
	if [[ ${CREATE_TEMPLATE_SOURCE:-github} == "local" ]]; then
		template_source="local"
	fi

	# Every template failure removes the half-created site.
	local template_step="docker_create_clone_template"
	if [[ $template_source == "local" ]]; then
		template_step="docker_create_copy_local_template"
	fi
	if ! "$template_step"; then
		ECHO_ERROR "Could not get the ${PROJECT_TYPE:-} template."
		docker_create_rollback
		return 1
	fi

	replace_templates_files
	# GitHub stays the source. In development, local Dockerfiles can still
	# replace the cloned ones without copying the whole template.
	if [[ $template_source == "github" && ${ENV_MODE:-} == "development" ]]; then
		docker_overlay_bundled_dockerfiles
	fi
	replace_variables

	if [[ -n "${CREATE_ENV_FILE:-}" ]]; then
		env_create "$CREATE_ENV_FILE"
	else
		env_create
	fi
	[[ "yes" == "${MULTISITE:-}" ]] && wp_multisite_env

	EMPTY_LINE
	ECHO_GREEN "Docker compose file set and container can be built and started"
	ECHO_TEXT "Starting Container"
	EMPTY_LINE

	if ! docker_compose_runner "${CREATE_COMPOSE_CMD:-up -d}" "${CREATE_COMPOSE_DIR:-}"; then
		docker_create_rollback
		return 1
	fi

	instances_set_status "active"
	ECHO_SUCCESS "Containers Started"

	# A hosts failure must not skip WordPress install. The browser would stay on the setup screen.
	if ! setup_hosts_file add; then
		ECHO_WARN_RED "Could not update the hosts file. Project setup will continue."
	fi
	if [[ ${CREATE_SKIP_PERMISSIONS:-0} -ne 1 ]]; then
		fix_permissions
	fi
	notice_windows_host add
	# Containers were just started. Restarting them here kills MariaDB and the
	# WordPress copy before the first boot finishes. Nginx still needs a reload
	# so the new host is picked up.
	if [[ ${CREATE_SKIP_DOCKER_RESTART:-0} -ne 1 ]]; then
		docker_nginx_restart || true
	fi

	if [[ -n "$after_up" ]]; then
		"$after_up"
	fi

	notice_project_vars "$notice_mode"

	unset CREATE_COMPOSE_CMD CREATE_COMPOSE_DIR CREATE_ENV_FILE
	unset CREATE_SYNC_PORT_FRONT CREATE_SKIP_PERMISSIONS CREATE_SKIP_DOCKER_RESTART
}
