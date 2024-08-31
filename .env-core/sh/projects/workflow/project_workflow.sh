#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

project_workflow() {
	unset_variables "PROJECT_TYPE"

	while true; do
		EMPTY_LINE
		ECHO_CYAN "===== Project Workflow ===="
		ECHO_YELLOW "0 - Return to main menu"
        ECHO_GREEN "1 - Change Status [active <=> inactive]"
		ECHO_GREEN "2 - Create project ZIP"
		ECHO_GREEN "3 - Project Unzip"

		action=$(GET_USER_INPUT "select_one_of")

		case $action in
		0)
			actions_existing_project
			;;
		1)
            get_existing_domains "======= Change Status ======="
			CURRENT_STATUS=$(awk '/'" $DOMAIN_NAME "'/{print $3}' "$FILE_INSTANCES" | head -n 1)

            if [[ "$CURRENT_STATUS" == 'active' ]]; then
                INSTANCES_STATUS="inactive"
            elif [[ $CURRENT_STATUS == 'inactive' ]]; then
                INSTANCES_STATUS="active"
            fi

			update_file_instances
            unset_variables "PROJECT_TYPE"
            ;;
		2)
			INSTANCES_STATUS="archive"
			zip_project
			unset_variables "PROJECT_TYPE"
			actions_existing_project
			;;
		3)
			INSTANCES_STATUS="active"
			unzip_project
			unset_variables "PROJECT_TYPE"
			actions_existing_project
			;;
		esac
	done
}
