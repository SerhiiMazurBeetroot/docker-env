#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_restart() {
	[[ "$DOMAIN_NAME" == '' ]] && running_projects_list "======= RESTART project ======="

	if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)')" ]; then
		[ -f "$PROJECT_DOCKER_DIR/docker-compose.yml" ] && docker_compose_runner "restart"

		docker_nginx_restart
	else
		ECHO_ERROR "Docker container doesn't exist [docker_restart] [$PROJECT_ROOT_DIR]"
	fi
}
