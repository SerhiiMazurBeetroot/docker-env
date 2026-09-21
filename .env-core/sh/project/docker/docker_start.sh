#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_start() {
	if ! has_domain_name; then
		stopped_projects_list "======== START project ========"
	fi

	docker_require_project_context "======== START project ========" || return 1

	if container_is_running; then
		ECHO_WARN_RED "Containers already running for this domain"
		project_services_menu
		return 0
	fi

	docker_start_project
}

# Non-interactive start for the current DOMAIN_NAME (used by Web UI).
docker_start_project() {
	docker_require_project_context "======== START project ========" || return 1

	if container_is_running; then
		ECHO_WARN_RED "Containers already running for this domain"
		return 0
	fi

	local compose_file="${PROJECT_DOCKER_DIR:-}/docker-compose.yml"

	if [[ "$(docker image ls --format '{{.Repository}}' | grep -E '(^|_|-)'"${DOCKER_CONTAINER_APP}"'($)')" ]] \
		&& [[ "$(docker volume ls --format '{{.Name}}' | grep -E '(^|_|-)'"${DOCKER_VOLUME_DB:-}"'($)')" ]]; then
		ECHO_SUCCESS "Site image and volume found"

		if [[ -f "$compose_file" ]]; then
			ECHO_YELLOW "Starting docker containers for this site"

			docker_compose_runner "up -d" || return 1

			ECHO_GREEN "Restarted now."
			docker_nginx_restart || true

			fix_permissions
			return 0
		fi

		ECHO_ERROR "Docker-compose file for this site was not found"
		ECHO_ERROR "Cannot restart site, in this case delete and start again"
		return 1
	fi

	# Images/volumes are often missing after a prune; compose can still start from the project files.
	ECHO_YELLOW "Site image or volume was not found"
	ECHO_YELLOW "Checking for Docker-compose file exist"

	if [[ ! -d "${PROJECT_DOCKER_DIR:-}" ]]; then
		ECHO_ERROR "DOCKER_DIR not found"
		return 1
	fi

	if find "$PROJECT_DOCKER_DIR" -type f -name 'docker-compose.yml' | grep -q .; then
		echo "Starting Container"
		docker_compose_runner "up -d" || return 1
		docker_nginx_restart || true
		return 0
	fi

	ECHO_ERROR "Docker-compose file not found"
	return 1
}
