#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

actions_existing_project() {
    while true; do
        EMPTY_LINE
        ECHO_CYAN "==== Existing sites ==="
        ECHO_YELLOW "0 - Return to main menu"
        ECHO_GREEN "1 - Docker actions"
        ECHO_GREEN "2 - Database actions"
        ECHO_GREEN "3 - WP actions"
        ECHO_CYAN "4 - List of existing projects"
        ECHO_GREEN "5 - GIT actions"
        ECHO_GREEN "6 - Archives actions"

        actions=$(GET_USER_INPUT "select_one_of")

        case $actions in
        0)
            main_actions
            ;;
        1)
            if [ $NGINX_EXISTS -eq 1 ]; then
                docker_actions
            else
                ECHO_ERROR "Nginx container not running"
                nginx_actions
            fi
            ;;
        2)
            if [ $NGINX_EXISTS -eq 1 ]; then
                database_actions
            else
                ECHO_ERROR "Nginx container not running"
                nginx_actions
            fi
            ;;
        3)
            wp_actions
            ;;
        4)
            existing_projects_list
            ;;
        5)
            git_actions
            ;;
        6)
            archives_actions
            ;;
        esac
    done
}
