#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_stop_all() {
	local type_filter="${1:-}"
	local domain

	ECHO_YELLOW "Stoping all containers..."

	while IFS= read -r domain; do
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

		database_auto_backup

		if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)')" ]; then

			if [ -d "$PROJECT_DOCKER_DIR" ]; then
				DOCKER_FILES=($(find "$PROJECT_DOCKER_DIR" -type f -name '*.yml'))

				[ -f "$DOCKER_FILES" ] && docker_compose_runner "down"
			fi

			ECHO_SUCCESS "Docker container stopped [$PROJECT_ROOT_DIR]"
		fi
		unset_variables
	done < <(instances_domain_names)

	docker_nginx_restart
}
