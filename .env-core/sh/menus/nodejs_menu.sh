#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

nodejs_menu() {
	load_project_modules

	local title="Node.js"
	[[ "${PROJECT_TYPE:-}" == "nodejs_api" ]] && title="Node.js API"

	while true; do
		EMPTY_LINE
		ECHO_CYAN "===== ${title} ===="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] npm install"
		ECHO_GREEN "[2] Logs"
		if [[ "${PROJECT_TYPE:-}" == "nodejs_api" ]]; then
			ECHO_GREEN "[3] Health"
		fi

		local action
		action=$(GET_USER_INPUT "select_one_of")

		case "${action:-0}" in
		0)
			return 0
			;;
		1)
			node_npm_install
			;;
		2)
			site_container_logs "${DOCKER_CONTAINER_APP:-}"
			;;
		3)
			if [[ "${PROJECT_TYPE:-}" == "nodejs_api" ]]; then
				node_health
			else
				ECHO_WARN_RED "Wrong option"
			fi
			;;
		*)
			ECHO_WARN_RED "Wrong option"
			;;
		esac
	done
}
