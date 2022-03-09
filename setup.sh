#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

# shellcheck disable=SC1091
source ./env-core/sh/scripts.sh

main_actions () {
    EMPTY_LINE
    check_package_availability
    detect_os
    check_instances_file_exists
    check_env_settings

    # Notice about updates to main menu
    [[ ! $ENV_UPDATES ]] && check_env_version
    [[ $ENV_UPDATES == "Everything up-to-date" ]] && ENV_UPDATES=""

    while true; do
        ECHO_INFO "======== devENV ======="
        ECHO_YELLOW "0 - Exit and do nothing"
        ECHO_GREEN "1 - Nginx"
        ECHO_GREEN "2 - New project"
        ECHO_GREEN "3 - Existing project"
        ECHO_KEY_VALUE "4 - ENV settings" "$ENV_UPDATES"

        read -rp "$(ECHO_YELLOW "Please select one of:")" userChoice

        case "$userChoice" in
        0)
            exit
            ;;
        1)
            nginx_actions
            ;;
        2)
            docker_wp_create
            unset_variables
            ;;
        3)
            existing_site_actions
            ;;
        4)
            env_settings
            ;;
        esac
    done

}

nginx_actions () {
    while true; do
        EMPTY_LINE
        ECHO_INFO "===== Nginx server ===="
        ECHO_YELLOW "0 - Return to main menu"
        ECHO_GREEN "1 - Setup"
        ECHO_GREEN "2 - Stop"
        ECHO_GREEN "3 - Start"
        ECHO_GREEN "4 - Restart"
        ECHO_GREEN "5 - Rebuild"

        read -rp "$(ECHO_YELLOW "Please select one of:")" proxy_actions

        case $proxy_actions in
            0)
                main_actions
                ;;
            1)
                nginx_proxy
                ;;
            2)
                docker_nginx_stop
                ;;
            3)
                docker_nginx_start
                ;;
            4)
                docker_nginx_restart
                ;;
            5)
                docker_nginx_rebuild
                ;;
        esac
    done
}

existing_site_actions () {
    while true; do
        EMPTY_LINE
        ECHO_INFO "==== Existing sites ==="
        ECHO_YELLOW "0 - Return to main menu"
        ECHO_GREEN "1 - Docker actions"
        ECHO_GREEN "2 - Database actions"

        read -rp "$(ECHO_YELLOW "Please select one of:")" actions        

        case $actions in
            0)
                main_actions
                ;;
            1)
                docker_actions
                ;;
            2)
                db_actions
                ;;
        esac
    done
}

db_actions () {
    while true; do
        EMPTY_LINE
        ECHO_INFO "========== DB actions ========="
        ECHO_YELLOW "0 - Return to the previous menu"
        ECHO_GREEN "1 - Update DB (import)"
        ECHO_GREEN "2 - Dump DB (export)"
        ECHO_GREEN "3 - Search-Replace"
        ECHO_GREEN "4 - Replace project from DB"
        read -rp "$(ECHO_YELLOW "Please select one of:")" actions

        case $actions in
            0)
                existing_site_actions
                ;;
            1)
                running_projects_list "========== IMPORT DB =========="
                import_db
                unset_variables
                ;;
            2)
                running_projects_list "========== EXPORT DB =========="
                export_db
                unset_variables
                ;;
            3)
                running_projects_list "====== Search-Replace DB ======"
                search_replace
                unset_variables
                ;;
            4)
                running_projects_list "=== Replace project from DB ==="
                replace_project_from_db
                docker_wp_rebuild
                docker_wp_restart
                import_db
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

docker_actions () {
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
        ECHO_INFO "7 - Run composer.json"
        read -rp "$(ECHO_YELLOW "Please select one of:")" actions

        case $actions in
            0)
                existing_site_actions
                ;;
            1)
                docker_wp_delete
                unset_variables
                ;;
            2)
                auto_backup_db
                docker_wp_stop
                unset_variables
                ;;
            3)
                docker_wp_start
                unset_variables
                ;;
            4)
                docker_wp_restart
                unset_variables
                ;;
            5)
                docker_wp_rebuild
                docker_wp_restart
                unset_variables
                ;;
            6)
                get_existing_domains "======= Fix permissions ======="
                fix_permissions
                unset_variables
                ;;
            7)
                wp_composer_install
                unset_variables
                existing_site_actions
                ;;
        esac
    done
}

env_settings () {
    check_env_version

    while true; do
        EMPTY_LINE
        ECHO_INFO "===== ENV settings ===="
        ECHO_YELLOW "0 - Return to main menu"
        ECHO_KEY_VALUE "1 - ENV_UPDATES:" "$ENV_UPDATES"
        ECHO_KEY_VALUE "2 - ENV_THEME:" "$ENV_THEME"
        read -rp "$(ECHO_YELLOW "Please select one of:")" settings

        case $settings in
            0)
                main_actions
                ;;
            1)
                update_env
                ;;
            2)
                change_env_theme
                ;;
        esac
    done
}

main_actions
