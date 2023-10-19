#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

running_projects_list() {
    unset_variables
    unset existing_container
    unset running_container
    ACTION=$1

    for PROJECT in "${AVAILABLE_PROJECTS[@]}"; do
        running_container+=($(docker ps --format '{{.Names}}' | grep -E ".*-$PROJECT($)" | sed -r 's/'-$PROJECT'/''/')) || true
    done

    #Check if running_container is from this environment
    for I in "${running_container[@]}"; do
        DOMAIN_EXISTS=$(awk '/'" $I "'/{print $5}' "$FILE_INSTANCES" | head -n 1) || true
        existing_container=${existing_container:+$existing_container }$DOMAIN_EXISTS
    done
    running_container=($existing_container)
    if [ "$running_container" ]; then
        while true; do
            EMPTY_LINE
            ECHO_CYAN "$ACTION"
            ECHO_YELLOW "[0] Return to the previous menu"

            print_list "${running_container[@]}"

            choice=$(GET_USER_INPUT "select_one_of")

            [ -z "$choice" ] && choice=-1
            if (("$choice" > 0 && "$choice" <= ${#running_container[@]})); then
                DOMAIN_NAME="${running_container[$(($choice - 1))]}"

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
