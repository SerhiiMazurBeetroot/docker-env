#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

ngrok_menu() {

    while true; do
        EMPTY_LINE
        ECHO_CYAN "===== Ngrok Agent ===="
        ECHO_YELLOW "0 - Return to the previous menu"
        ECHO_GREEN "1 - Setup"
        ECHO_GREEN "2 - Stop"
        ECHO_GREEN "3 - Start"
        ECHO_GREEN "4 - Restart"
        ECHO_GREEN "5 - Rebuild"
        ECHO_GREEN "6 - Your Authtoken"
        ECHO_GREEN "7 - Add New Endpoint"
        ECHO_GREEN "8 - Delete Endpoint"

        actions=$(GET_USER_INPUT "select_one_of")

        case $actions in
        0)
            system_services_menu
            ;;
        1)
            docker_ngrok_setup
            ;;
        2)
            docker_ngrok_stop
            ;;
        3)
            docker_ngrok_start
            ;;
        4)
            docker_ngrok_restart
            ;;
        5)
            docker_ngrok_rebuild
            ;;
        6)
            ngrok_save_token
            ;;
        7)
            ngrok_add_endpoint
            ;;
        8)
            ngrok_delete_endpoint
            ;;
        esac
    done
}
