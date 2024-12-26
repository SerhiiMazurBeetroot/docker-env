#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

project_services_menu() {
    while true; do
        EMPTY_LINE
        ECHO_CYAN "==== Project Services ==="
        ECHO_YELLOW "0 - Return to main menu"
        ECHO_GREEN "1 - Docker"
        ECHO_GREEN "2 - Database"
        ECHO_GREEN "3 - CLI"
        ECHO_CYAN "4 - List of existing projects"
        ECHO_GREEN "5 - Tools and Integrations"

        actions=$(GET_USER_INPUT "select_one_of")

        case $actions in
        0)
            main_actions
            ;;
        1)
            if [ $NGINX_EXISTS -eq 1 ]; then
                docker_menu
            else
                ECHO_ERROR "Nginx container not running"
                nginx_menu
            fi
            ;;
        2)
            if [ $NGINX_EXISTS -eq 1 ]; then
                database_menu
            else
                ECHO_ERROR "Nginx container not running"
                nginx_menu
            fi
            ;;
        3)
            ECHO_INFO "[exit] to exit the terminal"
            [[ "$DOMAIN_NAME" == '' ]] && running_projects_list "======= CLI ======="
            docker exec -it "$DOCKER_CONTAINER_APP" sh
            ;;

        4)
            existing_projects_list
            ;;
        5)
            project_tools_menu
            ;;
        esac
    done
}
