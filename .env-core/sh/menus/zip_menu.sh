#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Unzip an archive_*.zip and mark the site active again in instances.json.
restore_project_from_archive() {
	INSTANCES_STATUS="active"
	unzip_project
	unset_variables "PROJECT_TYPE"
}

zip_menu() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "========= Archive (ZIP) ========="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] Archive site to ZIP (stops Docker, removes site files)"
		ECHO_GREEN "[2] Restore site from ZIP"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			return 0
			;;
		1)
			INSTANCES_STATUS="archive"
			zip_project
			unset_variables "PROJECT_TYPE"
			;;
		2)
			restore_project_from_archive
			;;
		esac
	done
}
