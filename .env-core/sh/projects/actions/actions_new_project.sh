#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

actions_new_project() {
  while true; do
    EMPTY_LINE
    ECHO_INFO "===== Project type ===="
    ECHO_YELLOW "0 - Return to main menu"
    ECHO_GREEN "1 - Wordpress"
    ECHO_GREEN "2 - BEDROCK"
    ECHO_GREEN "3 - Simple PHP"
    ECHO_GREEN "4 - WP Next.js"
    ECHO_GREEN "5 - Node.js"

    read -rp "$(ECHO_YELLOW "Please select one of:")" PROJECT_TYPE

    case $PROJECT_TYPE in
    0)
      main_actions
      ;;
    1)
      docker_create_wp
      unset_variables "PROJECT_TYPE"
      ;;
    2)
      docker_create_bedrock
      unset_variables "PROJECT_TYPE"
      ;;
    3)
      docker_create_php
      unset_variables "PROJECT_TYPE"
      ;;
    4)
      docker_create_wp_next
      unset_variables "PROJECT_TYPE"
      ;;
    esac
  done
}
