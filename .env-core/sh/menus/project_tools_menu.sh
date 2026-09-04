#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

project_tools_menu() {
	unset_variables "PROJECT_TYPE"

	while true; do
		EMPTY_LINE
		ECHO_CYAN "===== Tools and Integrations ===="
		ECHO_YELLOW "0 - Return to the previous menu"
		ECHO_GREEN "1 - Change Status [active <=> inactive]"
		ECHO_GREEN "2 - GIT"
		ECHO_GREEN "3 - Archiving the project"
		ECHO_CYAN "4 - Other Services"
		# ECHO_GREEN "5 - Ngrok [Add New Endpoint]"

		action=$(GET_USER_INPUT "select_one_of")

		case $action in
		0)
			project_services_menu
			;;
		1)
			get_existing_domains "======= Change Status ======="
			CURRENT_STATUS=$(instances_get status)

			if [[ "$CURRENT_STATUS" == 'active' ]]; then
				INSTANCES_STATUS="inactive"
			elif [[ $CURRENT_STATUS == 'inactive' ]]; then
				INSTANCES_STATUS="active"
			fi

			update_file_instances
			unset_variables "PROJECT_TYPE"
			;;
		2)
			git_menu
			;;
		3)
			zip_menu
			;;
		4)
			other_services_menu
			;;
		5)
			# ngrok_add_endpoint
			;;
		esac
	done
}
