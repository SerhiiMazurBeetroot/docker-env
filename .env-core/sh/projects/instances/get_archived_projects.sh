#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

get_archived_projects() {
    ZIP_FILES=($(find . -type f -name "archive_*.zip"))

    if [[ $ZIP_FILES ]]; then
        while true; do
            EMPTY_LINE
            ECHO_INFO "======== UNZIP project ======="
            ECHO_YELLOW "[0] Return to the previous menu"

            for i in "${!ZIP_FILES[@]}"; do
                ECHO_KEY_VALUE "[$(($i + 1))]" "${ZIP_FILES[$i]}"
            done

            ((++i))
            read -rp "$(ECHO_YELLOW "Please select one of:")" choice

            [ -z "$choice" ] && choice=-1
            if (("$choice" > 0 && "$choice" <= $i)); then
                FILENAME=${ZIP_FILES[$(($choice - 1))]}
                PROJECT_TYPE="$(echo ${FILENAME} | grep -o '/[a-z]*/*' | sed 's/\///g')"
                DOMAIN_FULL="$(echo ${FILENAME} | grep -o "$PROJECT_TYPE"'_[A-Za-z0-9.-]*_' | sed 's/'$PROJECT_TYPE'_//g' | tr --delete _)"
                DOMAIN_NAME=$(awk '/'" $DOMAIN_FULL "'/{print $5}' "$FILE_INSTANCES" | head -n 1)
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
