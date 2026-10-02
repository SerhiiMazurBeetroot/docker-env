#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

primary_menu() {
	local updates_checked=0

	while true; do
		env_logo_draw
		ECHO_CYAN "======================="
		ECHO_YELLOW "[0] Exit"
		ECHO_GREEN "[1] System"
		ECHO_GREEN "[2] New site"
		ECHO_GREEN "[3] Sites"
		ECHO_CYAN "[4] Helpers"

		# The picture is already on screen. Ping only if today's check is missing.
		if [[ "$updates_checked" -eq 0 ]]; then
			updates_checked=1
			env_check_updates
		fi

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
