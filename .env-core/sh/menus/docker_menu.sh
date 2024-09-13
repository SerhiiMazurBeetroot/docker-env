#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_menu() {
    unset_variables "PROJECT_TYPE"

    while true; do
        EMPTY_LINE
        ECHO_CYAN "======== Docker actions ======="
        ECHO_YELLOW "0 - Return to the previous menu"
        ECHO_RED "1 - Permanently Remove"
        ECHO_GREEN "2 - Stop"
        ECHO_GREEN "3 - Start"
        ECHO_GREEN "4 - Restart"
        ECHO_GREEN "5 - Rebuild"
        ECHO_CYAN "6 - Fix permissions"

        actions=$(GET_USER_INPUT "select_one_of")

        case $actions in
        0)
            project_services_menu
            ;;
        1)
            INSTANCES_STATUS="remove"
            docker_delete
            unset_variables "PROJECT_TYPE"
            ;;
        2)
            database_auto_backup
            docker_stop
            unset_variables "PROJECT_TYPE"
            ;;
        3)
            docker_start
            notice_project_urls "open"
            unset_variables "PROJECT_TYPE"
            ;;
        4)
            docker_restart
            notice_project_urls "open"
            unset_variables "PROJECT_TYPE"
            ;;
        5)
            docker_rebuild
            docker_restart
            notice_project_urls "open"
            unset_variables "PROJECT_TYPE"
            ;;
        6)
            get_existing_domains "======= Fix permissions ======="
            fix_permissions
            unset_variables
            ;;
        esac
    done
}
