#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

get_existing_domains() {
    ACTION=$1

    if [ -z "$DOMAIN_NAME" ]; then
        EMPTY_LINE
        ECHO_CYAN "======== Project Status ======="
        ECHO_YELLOW "[0] Return to the services menu"
        ECHO_KEY_VALUE "[1]" "active [default]"
        ECHO_KEY_VALUE "[2]" "inactive"
        ECHO_KEY_VALUE "[3]" "all"

        first_choice=$(GET_USER_INPUT "select_one_of")

        if [[ "$first_choice" == "0" ]]; then
            project_services_menu
        fi

        filter=""
        case "$first_choice" in
        1) filter="^active\|" ;;            # starting with "active|"
        2) filter="^inactive\|" ;;          # starting with "inactive|"
        3) filter="^(active|inactive)\|" ;; # both "active|" and "inactive|"
        *)
            filter="^active\|"
            ;;
        esac

        string=$(awk '{print $3 $4 $5}' "$FILE_INSTANCES" | tail -n +2)

        if [ "$string" ]; then
            #Check project status is active
            string="$(echo "${string}" | grep -E "$filter")"
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
                        docker_menu
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
