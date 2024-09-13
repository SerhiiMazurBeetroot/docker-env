#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

get_existing_domains() {
    ACTION=$1

    if [ -z "$DOMAIN_NAME" ]; then
        string=$(awk '{print $3 $4 $5}' "$FILE_INSTANCES" | tail -n +2)

        if [ "$string" ]; then
            #Check project status is active
            string="$(echo "${string}" | grep -oE '(active|inactive)\|[A-Za-z0-9.-]*')"
            OptionList=($string)

            while true; do
                EMPTY_LINE
                ECHO_CYAN "$ACTION"
                ECHO_YELLOW "[0] Return to the previous menu"

                print_list "${OptionList[@]}"

                choice=$(GET_USER_INPUT "select_one_of")

                [ -z "$choice" ] && choice=-1
                if (("$choice" > 0 && "$choice" <= ${#OptionList[@]})); then
                    userChoice="${OptionList[$(($choice - 1))]}"
                    DOMAIN_NAME="$(echo "${userChoice}" | sed -E 's/(active|inactive)\|//g')"

                    get_project_dir "skip_question"
                    break
                else
                    if [ "$choice" == 0 ]; then
                        project_services_menu
                    else
                        ECHO_WARN_RED "Wrong option"
                    fi
                fi
            done
        else
            ECHO_ERROR "Sites don't exists"
            main_actions
        fi
    fi
}
