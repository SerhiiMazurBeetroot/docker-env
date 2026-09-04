#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_stop() {
	if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)')" ]; then

		if [ -f $PROJECT_DOCKER_DIR/docker-compose.yml ]; then
			docker_compose_runner "down"
		fi

		docker_nginx_restart

		ECHO_SUCCESS "Docker container stopped [$DOCKER_CONTAINER_APP]"
	else
		ECHO_ERROR "Docker container doesn't exist [docker_stop] [$PROJECT_ROOT_DIR]"
	fi
}
