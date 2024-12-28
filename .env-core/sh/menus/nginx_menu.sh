#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

nginx_menu() {
    docker_nginx_container

    while true; do
        EMPTY_LINE
        ECHO_CYAN "===== Nginx server ===="
        ECHO_YELLOW "0 - Return to main menu"
        ECHO_GREEN "1 - Setup"
        ECHO_GREEN "2 - Stop"
        ECHO_GREEN "3 - Start"
        ECHO_GREEN "4 - Restart"
        ECHO_GREEN "5 - Rebuild"
        ECHO_GREEN "6 - Re-Setup"

        proxy_actions=$(GET_USER_INPUT "select_one_of")

        case $proxy_actions in
        0)
            main_actions
            ;;
        1)
            docker_nginx_setup
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
        6)
            docker_nginx_resetup
            ;;
        esac
    done
}
