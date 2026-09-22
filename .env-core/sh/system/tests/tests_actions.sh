#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

tests_actions() {
	if [[ -n "${TEST_MODE:-}" ]]; then
		while true; do
			EMPTY_LINE
			ECHO_CYAN "======== TESTS actions ========"
			ECHO_YELLOW "[0] Return to the previous menu"
			ECHO_GREEN "[1] Create all AVAILABLE_PROJECTS"
			ECHO_GREEN "[2] Delete all AVAILABLE_PROJECTS"

			actions=$(GET_USER_INPUT "select_one_of")

			case $actions in
			0)
				system_menu
				;;
			1)
				if ! tests_create_all_projects; then
					ECHO_ERROR "Create-all tests finished with failures"
				fi
				;;
			2)
				tests_delete_all_projects
				;;
			esac
		done
	else
		ECHO_WARN_RED "Invalid selection. Please try again."
	fi
}

