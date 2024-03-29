#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

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
                DOMAIN_NAME=$(awk '/'" $DOMAIN_FULL "'/{print $5}' "$FILE_INSTANCES" | head -n 1)

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
