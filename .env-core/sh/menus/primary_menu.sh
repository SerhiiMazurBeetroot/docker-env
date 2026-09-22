#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

primary_menu() {
	while true; do
		$ENV_LOGO
		ECHO_CYAN "======================="
		ECHO_YELLOW "[0] Exit"
		ECHO_GREEN "[1] System"
		ECHO_GREEN "[2] New site"
		ECHO_GREEN "[3] Sites"
		ECHO_CYAN "[4] Helpers"

		userChoice=$(GET_USER_INPUT "select_one_of")

		case "$userChoice" in
		0)
			exit
			;;
		1)
			system_menu
			;;
		2)
			new_project_menu
			;;
		3)
			project_services_menu
			;;
		4)
			env_helpers_menu
			;;
		*)
			ECHO_WARN_RED "Invalid selection. Please try again."
			;;
		esac
	done

}
