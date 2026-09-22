#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

zip_menu() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "========= ZIP Workflow ========="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] Create project ZIP"
		ECHO_GREEN "[2] Project Unzip"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			return 0
			;;
		1)
			INSTANCES_STATUS="archive"
			zip_project
			unset_variables "PROJECT_TYPE"
			project_services_menu
			;;
		2)
			INSTANCES_STATUS="active"
			unzip_project
			unset_variables "PROJECT_TYPE"
			project_services_menu
			;;
		esac
	done
}
