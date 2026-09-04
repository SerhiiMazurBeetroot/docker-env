#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

new_project_menu() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "===== Project type ===="
		ECHO_YELLOW "0 - Return to main menu"

		build_visible_projects

		for ((i = 0; i < ${#AVAILABLE_PROJECTS[@]}; i++)); do
			index=$((i + 1))
			option="${PROJECT_TITLES[index - 1]}"
			ECHO_KEY_VALUE "[$index]" "$option"
		done

		PROJECT_TYPE=$(GET_USER_INPUT "select_one_of")

		case ${PROJECT_TYPE:-} in
		0)
			main_actions
			;;
		*)
			if ((PROJECT_TYPE < 1 || PROJECT_TYPE > ${#AVAILABLE_PROJECTS[@]})); then
				ECHO_WARN_RED "Invalid selection. Please try again."
				continue
			fi

			PROJECT_TYPE="${AVAILABLE_PROJECTS[PROJECT_TYPE - 1]}"
			SETUP_ACTION="create"
			create_project_by_type
			unset_variables "PROJECT_TYPE"
			;;
		esac
	done
}
