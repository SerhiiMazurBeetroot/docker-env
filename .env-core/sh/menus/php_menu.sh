#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

php_menu() {
	load_project_modules

	while true; do
		EMPTY_LINE
		ECHO_CYAN "===== PHP ===="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] Composer install"
		ECHO_GREEN "[2] Logs"

		local action
		action=$(GET_USER_INPUT "select_one_of")

		case "${action:-0}" in
		0)
			return 0
			;;
		1)
			php_composer_install
			;;
		2)
			site_container_logs "${DOCKER_CONTAINER_APP:-}"
			;;
		*)
			ECHO_WARN_RED "Wrong option"
			;;
		esac
	done
}
