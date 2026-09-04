#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

other_services_menu() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== Other Services ==="
		ECHO_YELLOW "0 - Return to the previous menu"
		ECHO_GREEN "1 - WP Workflow"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			project_services_menu
			;;
		1)
			wp_menu
			;;
		esac
	done
}
