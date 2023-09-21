#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

git_actions() {
    while true; do
        EMPTY_LINE
        ECHO_INFO "========= GIT actions ========="
        ECHO_YELLOW "0 - Return to the previous menu"
        ECHO_GREEN "1 - Clone from repo"
        ECHO_GREEN "2 - Create Github repo"
        ECHO_GREEN "3 - Create Gitlab repo"
        ECHO_GREEN "4 - Repo access"
        read -rp "$(ECHO_YELLOW "Please select one of:")" actions

        case $actions in
        0)
            actions_existing_project
            ;;
        1)
            git_clone_repo
            unset_variables
            actions_existing_project
            ;;
        2)
            get_existing_domains "====== Create Github Repo ====="
            git_create_repo_github
            unset_variables
            git_actions
            ;;
        3)
            get_existing_domains "====== Create GitLab Repo ====="
            git_create_repo_gitlab
            unset_variables
            git_actions
            ;;
        4)
            git_save_access
            git_actions
            ;;
        esac
    done
}
