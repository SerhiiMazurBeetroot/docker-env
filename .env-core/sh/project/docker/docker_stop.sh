#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_stop() {
	local compose_file

	docker_require_project_context "======= STOP project ========" || return 1

	compose_file="${PROJECT_DOCKER_DIR}/docker-compose.yml"

	if [[ -f "$compose_file" ]]; then
		local was_running=0
		if container_is_running; then
			was_running=1
		fi

		docker_compose_runner "down" || true
		if [[ "$was_running" -eq 1 ]]; then
			docker_nginx_restart || true
			ECHO_SUCCESS "Docker container stopped [${DOCKER_CONTAINER_APP}]"
		else
			ECHO_YELLOW "No running containers to stop [${DOMAIN_NAME:-}]"
		fi
		return 0
	fi

	if container_is_running; then
		ECHO_WARN_YELLOW "Compose file missing; cannot stop [${DOCKER_CONTAINER_APP}]"
		return 1
	fi

	ECHO_YELLOW "No running containers to stop [${PROJECT_ROOT_DIR:-}]"
	return 0
}
