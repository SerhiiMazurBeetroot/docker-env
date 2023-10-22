#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

git_clone_actions() {
    EMPTY_LINE
    yn=$(GET_USER_INPUT "question" "Start Clone?" "n")

    if [[ $yn == 'y' ]]; then
        while true; do
            EMPTY_LINE
            ECHO_CYAN "===== Clone actions ===="
            ECHO_YELLOW "0 - Return to previous menu"
            ECHO_GREEN "1 - Clone Project"
            ECHO_GREEN "2 - Clone WP Theme"

            actions=$(GET_USER_INPUT "select_one_of")

            case $actions in
            0)
                actions_existing_project
                break
                ;;
            1)
                git_clone_project
                break
                ;;
            2)
                git_clone_theme
                break
                ;;
            esac
        done
    fi
}
