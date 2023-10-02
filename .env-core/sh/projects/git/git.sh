#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

git_save_access() {
    #Github
    while true; do
        EMPTY_LINE
        read -rp "$(ECHO_YELLOW "Save/update Github access?") y/n " yn

        case $yn in
        [Yy]*)
            git_save_token_github || true
            git_save_user_github || true
            break
            ;;
        [Nn]*)
            break
            ;;

        *) echo "Please answer yes or no" ;;
        esac
    done

    #Gitlab
    while true; do
        EMPTY_LINE
        read -rp "$(ECHO_YELLOW "Save/update Gitlab access?") y/n " yn

        case $yn in
        [Yy]*)
            git_save_token_gitlab || true
            git_save_user_gitlab || true
            break
            ;;
        [Nn]*)
            break
            ;;

        *) echo "Please answer yes or no" ;;
        esac
    done
}

git_config_fileMode() {
    local PROJECT_DIR="${PWD}/$PROJECT_TYPE/$DOMAIN_FULL/"

    if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]; then
        git config core.fileMode false

        if [ -d "$PROJECT_DIR/.git" ] && git config core.fileMode false 2>/dev/null; then
            cd "$PROJECT_DIR" && git config core.fileMode false
            cd ../../
        else
            ECHO_YELLOW "No Git repository found in [$PROJECT_DIR]"
        fi
    fi
}
