#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_require_nginx() {
	if [[ ${NGINX_EXISTS:-0} -ne 1 ]]; then
		ECHO_ERROR "Nginx container not running"
		nginx_menu
		return 1
	fi
}

docker_create_require_new_site() {
	if [[ ${DOMAIN_EXISTS:-0} != 0 ]]; then
		ECHO_ERROR "Site already exists"
		return 1
	fi
}

# Optional flags (unset at end of docker_create_project):
#   CREATE_TEMPLATE=clone|copy|wpnextjs|directus_nextjs|nodejs|laravel
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

	case "${CREATE_TEMPLATE:-clone}" in
	copy)
		git_clone_templates_files "copy"
		;;
	wpnextjs)
		cp -R "$ENV_DIR/.env-core/templates/wpnextjs/." "$PROJECT_ROOT_DIR/"
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
		git_clone_templates_files
		;;
	esac

	replace_templates_files
	# GitHub docker-env-template-* is the source. Overlay local Dockerfiles
	# only while ENV_MODE=development (quick test/fix without pushing).
	if [[ ${ENV_MODE:-} == "development" ]]; then
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
		instances_set_status "inactive"
		return 1
	fi

	instances_set_status "active"
	ECHO_SUCCESS "Containers Started"

	setup_hosts_file add
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
