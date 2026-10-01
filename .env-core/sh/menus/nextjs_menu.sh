#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

nextjs_menu() {
	load_project_modules

	while true; do
		EMPTY_LINE
		ECHO_CYAN "===== Next.js ===="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] npm install"
		ECHO_GREEN "[2] npm run build"
		ECHO_GREEN "[3] Logs"

		local action
		action=$(GET_USER_INPUT "select_one_of")

		case "${action:-0}" in
		0)
			return 0
			;;
		1)
			nextjs_npm install
			;;
		2)
			nextjs_npm run build
			;;
		3)
			site_container_logs "${DOMAIN_NAME:-}-nextjs"
			;;
		*)
			ECHO_WARN_RED "Wrong option"
			;;
		esac
	done
}
