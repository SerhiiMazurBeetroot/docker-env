#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

archives_actions() {
	unset_variables "PROJECT_TYPE"

	while true; do
		EMPTY_LINE
		ECHO_CYAN "===== Archives actions ===="
		ECHO_YELLOW "0 - Return to main menu"
		ECHO_GREEN "1 - ZIP"
		ECHO_GREEN "2 - Unzip"

		action=$(GET_USER_INPUT "select_one_of")

		case $action in
		0)
			actions_existing_project
			;;
		1)
			STATUS="archive"
			zip_project
			unset_variables "PROJECT_TYPE"
			actions_existing_project
			;;
		2)
			STATUS="active"
			unzip_project
			unset_variables "PROJECT_TYPE"
			actions_existing_project
			;;
		esac
	done
}
