#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

actions_new_project() {
  while true; do
    EMPTY_LINE
    ECHO_INFO "===== Project type ===="
    ECHO_YELLOW "0 - Return to main menu"

    print_list "${AVAILABLE_PROJECTS_ARRAY[@]}"

    read -rp "$(ECHO_YELLOW "Please select one of:")" PROJECT_TYPE

    case $PROJECT_TYPE in
    0)
      main_actions
      ;;
    *)
      # Validate the selected project type
      if ((PROJECT_TYPE < 1 || PROJECT_TYPE > ${#AVAILABLE_PROJECTS[@]})); then
        EMPTY_LINE
        ECHO_WARN_RED "Invalid selection. Please try again."
        continue
      fi

      selected_project="${AVAILABLE_PROJECTS[PROJECT_TYPE - 1]}"

      case $selected_project in
      "wordpress")
        docker_create_wp
        unset_variables "PROJECT_TYPE"
        ;;
      "bedrock")
        docker_create_bedrock
        unset_variables "PROJECT_TYPE"
        ;;
      "php")
        docker_create_php
        unset_variables "PROJECT_TYPE"
        ;;
      "wpnextjs")
        docker_create_wp_next
        unset_variables "PROJECT_TYPE"
        ;;
      "nodejs")
        docker_create_nodejs
        unset_variables "PROJECT_TYPE"
        ;;
      esac
      ;;
    esac
  done
}
