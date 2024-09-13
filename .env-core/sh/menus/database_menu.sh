#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

database_menu() {
    while true; do
        EMPTY_LINE
        ECHO_CYAN "========== DB actions ========="
        ECHO_YELLOW "0 - Return to the previous menu"
        ECHO_GREEN "1 - Update DB (import)"
        ECHO_GREEN "2 - Dump DB (export)"
        ECHO_GREEN "3 - Search-Replace"
        ECHO_GREEN "4 - Replace project from DB"

        actions=$(GET_USER_INPUT "select_one_of")

        case $actions in
        0)
            project_services_menu
            ;;
        1)
            running_projects_list "========== IMPORT DB =========="
            database_import
            unset_variables
            ;;
        2)
            running_projects_list "========== EXPORT DB =========="
            database_export
            unset_variables
            ;;
        3)
            running_projects_list "====== Search-Replace DB ======"
            database_search_replace
            unset_variables
            ;;
        4)
            running_projects_list "=== Replace project from DB ==="
            database_replace_project_from_db
            docker_rebuild
            docker_restart
            database_import
            fix_permissions
            edit_file_wp_config_setup_beetroot
            wp_get_default_theme
            wp_composer_install
            edit_file_env_setup_beetroot
            fix_linux_watchers
            edit_file_gitignore
            unset_variables
            ;;
        esac
    done
}
