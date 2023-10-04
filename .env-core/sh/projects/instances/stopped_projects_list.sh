#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

stopped_projects_list() {
    unset existing_container
    unset stopped_container
    unset running_container
    ACTION=$1

    for PROJECT in "${AVAILABLE_PROJECTS[@]}"; do
        running_container+=($(docker ps --format '{{.Names}}' | grep -E ".*-$PROJECT(\$)" | sed -r 's/'-$PROJECT'/''/')) || true
    done

    existing_string=$(awk '{print $3 $4 $5}' "$FILE_INSTANCES" | tail -n +2)

    #Check project status is active
    existing_string="$(echo ${existing_string} | grep -o 'active|[A-Za-z0-9.-]*' | sed 's/active|//g')"

    for I in $existing_string; do
        existing_container=${existing_container:+$existing_container }$I
    done

    if [[ "$running_container" || "$existing_container" ]]; then
        running_container=$(printf "%s\|" "${running_container[@]}")

        stopped_container=($(echo "$existing_container" | sed "s/\($running_container\)//g"))

        while true; do
            EMPTY_LINE
            ECHO_INFO "$ACTION"
            ECHO_YELLOW "[0] Return to the previous menu"

            print_list "${stopped_container[@]}"

            read -rp "$(ECHO_YELLOW "Please select one of:")" choice

            [ -z "$choice" ] && choice=-1
            if (("$choice" > 0 && "$choice" <= ${#stopped_container[@]})); then
                DOMAIN_NAME="${stopped_container[$(($choice - 1))]}"

                get_project_dir "skip_question"
                break
            else
                if [ "$choice" == 0 ]; then
                    actions_existing_project
                else
                    ECHO_WARN_RED "Wrong option"
                fi
            fi
        done
    else
        ECHO_ERROR "Sites not running"
        actions_existing_project
    fi
}
