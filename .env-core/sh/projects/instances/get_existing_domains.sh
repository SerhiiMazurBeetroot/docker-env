#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

get_existing_domains() {
    ACTION=$1

    if [ -z "$DOMAIN_NAME" ]; then
        string=$(awk '{print $3 $4 $5}' "$FILE_INSTANCES" | tail -n +2)

        #Check project status is active
        string="$(echo ${string} | grep -o 'active|[A-Za-z0-9.-]*' | sed 's/active|//g')"

        OptionList=($string)

        if [ "$string" ]; then
            while true; do
                EMPTY_LINE
                ECHO_INFO "$ACTION"
                ECHO_YELLOW "[0] Return to the previous menu"

                print_list "${OptionList[@]}"

                read -rp "$(ECHO_YELLOW "Please select one of:")" choice

                [ -z "$choice" ] && choice=-1
                if (("$choice" > 0 && "$choice" <= ${#OptionList[@]})); then
                    DOMAIN_NAME="${OptionList[$(($choice - 1))]}"
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
            ECHO_ERROR "Sites don't exists"
            main_actions
        fi
    fi
}
