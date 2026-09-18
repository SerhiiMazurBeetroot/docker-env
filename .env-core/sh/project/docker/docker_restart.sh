#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_restart() {
	docker_require_project_context "======= RESTART project ========" || return 1

	if container_is_running; then
		[[ -f "${PROJECT_DOCKER_DIR}/docker-compose.yml" ]] && docker_compose_runner "restart"
		docker_nginx_restart
	else
		ECHO_ERROR "Docker container doesn't exist [docker_restart] [${PROJECT_ROOT_DIR:-}]"
		return 1
	fi
}
