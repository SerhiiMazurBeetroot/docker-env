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
		ECHO_ERROR "Site already exists"
		return 1
	fi
}

# Sibling checkout first, then the copy bundled in this repo.
docker_create_copy_local_template() {
	local sibling="$ENV_DIR/../docker-env-templates/docker-env-template-${PROJECT_TYPE}"
	local bundled="$ENV_DIR/.env-core/templates/${PROJECT_TYPE}"
	local src=""

	if [[ -d "$sibling" ]]; then
		src="$sibling"
	elif [[ -d "$bundled" ]]; then
		src="$bundled"
	else
		ECHO_ERROR "Local template not found for ${PROJECT_TYPE:-}"
		return 1
	fi

	ECHO_INFO "Using local template ${src}"
	rsync -a --exclude .git "$src/" "$PROJECT_ROOT_DIR/"
}

# Optional flags (unset at end of docker_create_project). docker_create_dispatch
# sets these from PROJECT_CREATE_FLAGS in core/available_projects.sh:
#   CREATE_TEMPLATE=clone|copy|wordpress_nextjs|directus_nextjs|nodejs|laravel
#   CREATE_TEMPLATE_SOURCE=github|local
#     github is the default and clones docker-env-template-$PROJECT_TYPE.
#     local copies the sibling checkout, or .env-core/templates/$PROJECT_TYPE.
#   CREATE_COMPOSE_CMD="up -d"
#   CREATE_COMPOSE_DIR=
#   CREATE_ENV_FILE=
#   CREATE_SYNC_PORT_FRONT=1
#   CREATE_NODE_PORTS=1
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
	if [[ ${CREATE_NODE_PORTS:-0} -eq 1 ]]; then
		MONGODB_DOCKER_PORT=$((PORT + 23707))
		MONGODB_LOCAL_PORT=$((PORT + 3707))
		MONGO_EXPRESS_PORT=$((PORT + 4771))
	fi

	get_project_dir "skip_question"
	print_to_file_instances "building"
	mkdir -p "$PROJECT_ROOT_DIR"

	# github | local. Export CREATE_TEMPLATE_SOURCE=local to skip the clone.
	local template_source="github"
	if [[ ${CREATE_TEMPLATE_SOURCE:-github} == "local" ]]; then
		template_source="local"
	fi

	case "${CREATE_TEMPLATE:-clone}" in
	copy)
		git_clone_templates_files "copy"
		;;
	wordpress_nextjs)
		cp -R "$ENV_DIR/.env-core/templates/wordpress_nextjs/." "$PROJECT_ROOT_DIR/"
		;;
	directus_nextjs)
		cp -R "$ENV_DIR/.env-core/templates/directus_nextjs/." "$PROJECT_ROOT_DIR/"
		;;
	nodejs)
		rsync -av "$ENV_DIR/.env-core/templates/nodejs/" "$PROJECT_ROOT_DIR/"
		;;
	laravel)
		cp -R "$ENV_DIR/.env-core/templates/laravel/." "$PROJECT_ROOT_DIR/"
		;;
	*)
		if [[ $template_source == "local" ]]; then
			if ! docker_create_copy_local_template; then
				docker_create_rollback
				return 1
			fi
		else
			if ! git_clone_templates_files; then
				docker_create_rollback
				return 1
			fi
		fi
		;;
	esac

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

	unset CREATE_TEMPLATE CREATE_COMPOSE_CMD CREATE_COMPOSE_DIR CREATE_ENV_FILE
	unset CREATE_SYNC_PORT_FRONT CREATE_NODE_PORTS CREATE_SKIP_PERMISSIONS CREATE_SKIP_DOCKER_RESTART
}
