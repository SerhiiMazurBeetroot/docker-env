#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

tests_actions() {
	if [[ $TEST_MODE ]]; then
		while true; do
			EMPTY_LINE
			ECHO_CYAN "======== TESTS actions ========"
			ECHO_YELLOW "0 - Return to the previous menu"
			ECHO_GREEN "1 - Create all AVAILABLE_PROJECTS"
			ECHO_GREEN "2 - Delete all AVAILABLE_PROJECTS"

			actions=$(GET_USER_INPUT "select_one_of")

			case $actions in
			0)
				main_actions
				;;
			1)
				tests_create_all_projects
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

echo_tests_actions() {
	if [[ $ENV_MODE == 'development' ]]; then
		TEST_MODE=true
		ECHO_RED "* - Run tests"
	fi
}
