#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_stop() {
	local compose_file

	docker_require_project_context "======= STOP project ========" || return 1

	compose_file="${PROJECT_DOCKER_DIR}/docker-compose.yml"

	if [[ -f "$compose_file" ]]; then
		local project_containers
		project_containers=$($DOCKER_COMPOSE_CMD --project-directory "$PROJECT_DOCKER_DIR" ps -aq 2>/dev/null | wc -l | tr -d '[:space:]')
		if [[ "${project_containers:-0}" -gt 0 ]]; then
			docker_compose_runner "down"
			docker_nginx_restart
			ECHO_SUCCESS "Docker container stopped [${DOCKER_CONTAINER_APP}]"
			return 0
		fi
	fi

	if container_is_running; then
		[[ -f "$compose_file" ]] && docker_compose_runner "down"
		docker_nginx_restart
		ECHO_SUCCESS "Docker container stopped [${DOCKER_CONTAINER_APP}]"
	else
		ECHO_ERROR "Docker container doesn't exist [docker_stop] [${PROJECT_ROOT_DIR:-}]"
		return 1
	fi
}
