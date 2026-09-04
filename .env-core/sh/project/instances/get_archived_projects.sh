#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

get_archived_projects() {
	ZIP_FILES=($(find . -type f -name "archive_*.zip"))

	if [[ $ZIP_FILES ]]; then
		while true; do
			EMPTY_LINE
			ECHO_CYAN "======== UNZIP project ======="
			ECHO_YELLOW "[0] Return to the previous menu"

			print_list "${ZIP_FILES[@]}"

			choice=$(GET_USER_INPUT "select_one_of")

			[ -z "$choice" ] && choice=-1
			if (("$choice" > 0 && "$choice" <= ${#ZIP_FILES[@]})); then
				FILENAME=${ZIP_FILES[$(($choice - 1))]}
				PROJECT_TYPE="$(echo ${FILENAME} | grep -o '/[a-z]*/*' | sed 's/\///g')"
				DOMAIN_FULL="$(echo ${FILENAME} | grep -o "$PROJECT_TYPE"'_[A-Za-z0-9.-]*_' | sed 's/'$PROJECT_TYPE'_//g' | tr -d _)"
				DOMAIN_NAME=$(instances_get domain_name "$DOMAIN_FULL" domain_full)

				get_project_dir "skip_question"
				break
			else
				if [ "$choice" == 0 ]; then
					archives_actions
				else
					ECHO_WARN_RED "Wrong option"
				fi
			fi
		done
	fi
}
