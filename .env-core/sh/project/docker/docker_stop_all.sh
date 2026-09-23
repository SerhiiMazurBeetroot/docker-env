#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_stop_all() {
	local type_filter="${1:-}"
	local domain
	local failed=0

	ECHO_YELLOW "Stopping all containers..."

	# Read names on fd 3. docker exec -i (DB dump) and compose read stdin,
	# which would otherwise consume the rest of this list and stop one project.
	while IFS= read -r domain <&3; do
		[[ -n "$domain" ]] || continue
		DOMAIN_NAME="$domain"
		reset_session_var PROJECT_TYPE
		reset_session_var PROJECT_DOCKER_DIR
		reset_session_var PROJECT_ROOT_DIR
		reset_session_var DOCKER_CONTAINER_APP

		get_project_dir "skip_question" || {
			unset_variables
			continue
		}

		if [[ -n "$type_filter" && "${PROJECT_TYPE:-}" != "$type_filter" ]]; then
			unset_variables
			continue
		fi

		if ! container_is_running; then
			unset_variables
			continue
		fi

		database_auto_backup || true

		ECHO_YELLOW "Stopping [${DOMAIN_NAME}]"
		if [[ -f "${PROJECT_DOCKER_DIR:-}/docker-compose.yml" ]]; then
			if docker_compose_runner "down"; then
				ECHO_SUCCESS "Docker container stopped [${PROJECT_ROOT_DIR}]"
			else
				ECHO_ERROR "Failed to stop [${DOMAIN_NAME}]"
				failed=1
			fi
		else
			ECHO_ERROR "Compose file missing; cannot stop [${DOMAIN_NAME}]"
			failed=1
		fi
		unset_variables
	done 3< <(instances_domain_names)

	docker_nginx_restart || true
	return "$failed"
}
