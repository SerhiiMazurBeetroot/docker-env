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

    while true; do
        ECHO_YELLOW "0 - Exit and do nothing"
        ECHO_GREEN "1 - Nginx"
        ECHO_GREEN "2 - New project"
        ECHO_GREEN "3 - Existing project"
        ECHO_INFO "4 - ENV settings"

        read -rp "$(ECHO_YELLOW "Please select one of:")" userChoice

        case "$userChoice" in
        0)
            exit
            ;;
        1)
            nginx_actions
            exit
            ;;
        2)
            docker_wp_create

            exit
            ;;
        3)
            existing_site_actions
            exit
            ;;
        4)
            env_settings
            exit
            ;;
        esac
    done

}

nginx_actions () {
    while true; do
        EMPTY_LINE
        ECHO_INFO "Your Next choice"
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
                exit
                ;;
            1)
                nginx_proxy
                exit
                ;;
            2)
                docker_nginx_stop
                exit
                ;;
            3)
                docker_nginx_start
                exit
                ;;
            4)
                docker_nginx_restart
                exit
                ;;
            5)
                docker_nginx_rebuild
                exit
                ;;
        esac
    done
}

existing_site_actions () {
    while true; do
        EMPTY_LINE
        ECHO_INFO "Your Next choice"
        ECHO_YELLOW "0 - Return to main menu"
        ECHO_ATTENTION "1 - Permanently Remove"
        ECHO_GREEN "2 - Stop"
        ECHO_GREEN "3 - Start"
        ECHO_GREEN "4 - Restart"
        ECHO_GREEN "5 - Rebuild"
        ECHO_INFO "6 - List of existing projects"
        ECHO_INFO "7 - Database actions"
        ECHO_INFO "8 - Fix permissions"
        ECHO_INFO "9 - Clone from repo"


        read -rp "$(ECHO_YELLOW "Please select one of:")" actions

        case $actions in
            0)
                main_actions
                exit
                ;;
            1)
                docker_wp_delete
                exit
                ;;
            2)
                auto_backup_db
                docker_wp_stop
                exit
                ;;
            3)
                docker_wp_start
                exit
                ;;
            4)
                docker_wp_restart
                exit
                ;;
            5)
                docker_wp_rebuild
                docker_wp_restart
                exit
                ;;
            6)
                existing_projects_list
                ;;
            7)
                db_actions
                exit
                ;;
            8)
                fix_permissions
                exit
                ;;
            9)
                clone_repo
                exit
                ;;

        esac
    done
}

db_actions () {
    while true; do
        EMPTY_LINE
        ECHO_YELLOW "0 - Return to main menu"
        ECHO_GREEN "1 - Update DB (import)"
        ECHO_GREEN "2 - Dump DB (export)"
        ECHO_GREEN "3 - Search-Replace"
        read -rp "$(ECHO_YELLOW "Please select one of:")" actions

        case $actions in
            0)
                main_actions
                exit
                ;;
            1)
                import_db
                exit
                ;;
            2)
                export_db
                break
                ;;
            3)
                search_replace
                break
                ;;
        esac
    done
}

env_settings () {
    check_env_version

    while true; do
        EMPTY_LINE
        ECHO_YELLOW "0 - Return to main menu"
        ECHO_KEY_VALUE "1 - ENV_UPDATES:" "$ENV_UPDATES"
        ECHO_KEY_VALUE "2 - ENV_THEME:" "$ENV_THEME"
        read -rp "$(ECHO_YELLOW "Please select one of:")" settings

        case $settings in
            0)
                main_actions
                exit
                ;;
            1)
                update_env
                exit
                ;;
            2)
                change_env_theme
                break
                ;;
        esac
    done
}

main_actions
