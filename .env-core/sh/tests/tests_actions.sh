#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

tests_actions() {
    while true; do
        EMPTY_LINE
        ECHO_CYAN "======== TESTS actions ========"
        ECHO_YELLOW "0 - Return to the previous menu"
        ECHO_GREEN "1 - Create all AVAILABLE_PROJECTS"

        actions=$(GET_USER_INPUT "select_one_of")

        case $actions in
        0)
            main_actions
            ;;
        1)
            tests_create_all_projects
            ;;
        esac
    done
}
