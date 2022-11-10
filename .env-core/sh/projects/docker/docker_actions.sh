#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_actions() {
    unset_variables "PROJECT_TYPE"

    while true; do
        EMPTY_LINE
        ECHO_INFO "======== Docker actions ======="
        ECHO_YELLOW "0 - Return to the previous menu"
        ECHO_ATTENTION "1 - Permanently Remove"
        ECHO_GREEN "2 - Stop"
        ECHO_GREEN "3 - Start"
        ECHO_GREEN "4 - Restart"
        ECHO_GREEN "5 - Rebuild"
        ECHO_INFO "6 - Fix permissions"
        read -rp "$(ECHO_YELLOW "Please select one of:")" actions

        case $actions in
        0)
            actions_existing_project
            ;;
        1)
            STATUS="remove"
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
            notice_project_urls
            unset_variables "PROJECT_TYPE"
            ;;
        4)
            docker_restart
            notice_project_urls
            unset_variables "PROJECT_TYPE"
            ;;
        5)
            docker_rebuild
            docker_restart
            notice_project_urls
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
