#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_rebuild() {
	docker_require_project_context "======= REBUILD project ========" || return 1

	if [[ ! -f "${PROJECT_DOCKER_DIR}/docker-compose.yml" ]]; then
		ECHO_ERROR "docker-compose.yml not found: ${PROJECT_DOCKER_DIR}"
		return 1
	fi

	docker_compose_runner "up -d --force-recreate -V --no-deps --build"
}
