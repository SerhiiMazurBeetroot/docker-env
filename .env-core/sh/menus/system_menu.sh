#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

system_menu() {
	load_system_modules

	while true; do
		EMPTY_LINE
		ECHO_CYAN "======== System  ======="
		ECHO_YELLOW "0 - Return to main menu"
		ECHO_GREEN "1 - Nginx"
		ECHO_KEY_VALUE "3 - Web UI" "$(webui_status_label)"
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
		3)
			webui_menu
			;;
		9)
			env_settings
			;;
		10)
			load_system_tests
			tests_actions
			;;
		*)
			ECHO_WARN_RED "Invalid selection. Please try again."
			;;
		esac
	done

}

echo_tests_actions() {
	if [[ ${ENV_MODE:-} == 'development' ]]; then
		TEST_MODE=true
		ECHO_RED "10 - Run tests"
	fi
}
