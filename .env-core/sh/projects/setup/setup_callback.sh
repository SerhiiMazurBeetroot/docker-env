#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

check_data_before_continue_callback() {
    EMPTY_LINE
    ECHO_INFO "Check everything before proceeding:"
    EMPTY_LINE

    while true; do
        notice_project_vars

        yn=$(GET_USER_INPUT "question" "Is that correct?")

        case $yn in
        [Yy]*)
            break
            ;;
        [Nn]*)
            ECHO_ERROR "Enter correct information"
            unset_variables

            # Run next function again
            ($1)
            break
            ;;

        *) echo "Please answer yes or no" ;;
        esac
    done
}

setup_installation_type_callback() {
    unset_variables

    while true; do
        EMPTY_LINE
        ECHO_CYAN "==== $PROJECT_TYPE type ==="
        ECHO_YELLOW "[0] Return to main menu"
        ECHO_KEY_VALUE "[1]" "default"
        ECHO_KEY_VALUE "[2]" "custom"
        ECHO_KEY_VALUE "[3]" "beetroot"
        SETUP_TYPE=$(GET_USER_INPUT "select_one_of")

        case $SETUP_TYPE in
        0)
            main_actions
            ;;
        1)
            get_domain_name
            check_domain_exists

            if [[ $DOMAIN_EXISTS == 0 ]]; then
                get_project_dir "$@"
                set_project_args
            else
                ECHO_ERROR "Site already exists"

                # Run next function again
                ($1)
            fi

            break
            ;;
        2)
            get_domain_name
            check_domain_exists

            if [[ $DOMAIN_EXISTS == 0 ]]; then
                get_project_dir "$@"
                set_custom_args
            else
                ECHO_ERROR "Site already exists"

                # Run next function again
                ($1)
            fi

            break
            ;;
        3)
            get_domain_name
            check_domain_exists

            if [[ $DOMAIN_EXISTS == 0 ]]; then
                setup_beetroot_args "$@"
            else
                ECHO_ERROR "Site already exists"

                # Run next function again
                ($1)
            fi

            break
            ;;
        esac
    done
}
