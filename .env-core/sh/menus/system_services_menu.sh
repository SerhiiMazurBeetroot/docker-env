#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

system_services_menu() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "======== System Services ======="
		ECHO_YELLOW "0 - Return to main menu"
		ECHO_GREEN "1 - Nginx"
		# ECHO_GREEN "2 - Ngrok"
		ECHO_KEY_VALUE "9 - Settings" "$ENV_UPDATES"

		echo_tests_actions

		userChoice=$(GET_USER_INPUT "select_one_of")

		case "$userChoice" in
		0)
			primary_menu
			;;
		1)
			nginx_menu
			;;
		2)
			# ngrok_menu
			;;
		9)
			env_settings
			;;
		10)
			tests_actions
			;;
		*)
			ECHO_WARN_RED "Invalid selection. Please try again."
			;;
		esac
	done

}
