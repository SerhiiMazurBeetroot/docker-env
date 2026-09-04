#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_rebuild() {
	get_existing_domains "======= REBUILD project ======="

	if [ -f $PROJECT_DOCKER_DIR/docker-compose.yml ]; then
		docker_compose_runner "up -d --force-recreate -V --no-deps --build"
	fi
}
