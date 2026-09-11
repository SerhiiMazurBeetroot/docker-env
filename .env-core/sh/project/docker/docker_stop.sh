#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_stop() {
	local compose_file="${PROJECT_DOCKER_DIR}/docker-compose.yml"
	local project_containers

	if [[ -f "$compose_file" ]]; then
		project_containers=$($DOCKER_COMPOSE_CMD --project-directory "$PROJECT_DOCKER_DIR" ps -aq 2>/dev/null | wc -l | tr -d '[:space:]')
		if [[ "${project_containers:-0}" -gt 0 ]]; then
			docker_compose_runner "down"
			docker_nginx_restart
			ECHO_SUCCESS "Docker container stopped [$DOCKER_CONTAINER_APP]"
			return 0
		fi
	fi

	if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)')" ]; then
		[[ -f "$compose_file" ]] && docker_compose_runner "down"
		docker_nginx_restart
		ECHO_SUCCESS "Docker container stopped [$DOCKER_CONTAINER_APP]"
	else
		ECHO_ERROR "Docker container doesn't exist [docker_stop] [$PROJECT_ROOT_DIR]"
	fi
}
