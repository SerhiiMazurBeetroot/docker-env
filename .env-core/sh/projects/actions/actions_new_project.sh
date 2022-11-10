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

    read -rp "$(ECHO_YELLOW "Please select one of:")" PROJECT_TYPE

    case $PROJECT_TYPE in
    0)
      main_actions
      ;;
    1)
      docker_create_wp
      unset_variables
      ;;
    2)
      docker_create_bedrock
      unset_variables
      ;;
    3)
      docker_create_php
      unset_variables
      ;;
    esac
  done
}
