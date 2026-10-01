#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

system_menu() {
	load_system_modules

	while true; do
		EMPTY_LINE
		ECHO_CYAN "======== System  ======="
		ECHO_YELLOW "[0] Return to main menu"
		ECHO_GREEN "[1] Nginx"
		ECHO_KEY_VALUE "[2] Web UI" "$(webui_status_label)"
		ECHO_KEY_VALUE "[3] Settings" "$ENV_UPDATES"

		echo_tests_actions

		userChoice=$(GET_USER_INPUT "select_one_of")

		case "$userChoice" in
		0)
			return 0
			;;
		1)
			nginx_menu
			;;
		2)
			webui_menu
			;;
		3)
			env_settings
			;;
		4)
			if [[ ${ENV_MODE:-} == 'development' ]]; then
				load_system_tests
				tests_actions
			else
				ECHO_WARN_RED "Invalid selection. Please try again."
			fi
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
		ECHO_RED "[4] Run tests"
	fi
}
