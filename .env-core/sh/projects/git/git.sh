#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

git_save_access() {
    #Github
    while true; do
        yn=$(GET_USER_INPUT "question" "Save/update Github access?")

        case $yn in
        [Yy]*)
            git_save_token_github || true
            git_save_user_github || true
            break
            ;;
        [Nn]*)
            break
            ;;

        *) echo "Please answer [y/n]" ;;
        esac
    done

    #Gitlab
    while true; do
        yn=$(GET_USER_INPUT "question" "Save/update Gitlab access?")

        case $yn in
        [Yy]*)
            git_save_token_gitlab || true
            git_save_user_gitlab || true
            break
            ;;
        [Nn]*)
            break
            ;;

        *) echo "Please answer [y/n]" ;;
        esac
    done
}

git_config_fileMode() {
    local PROJECT_DIR="${PWD}/$PROJECT_TYPE/$DOMAIN_FULL/"

    if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]; then
        git config core.fileMode false

        #TODO: find a solution in the future without using '*'
        safe_directories=$(git config --global --get-all safe.directory)
        patterns=("*" "$PROJECT_DIR")

        for pattern in "${patterns[@]}"; do
            if echo "$safe_directories" | grep -q "$pattern"; then
                ECHO_TEXT "Pattern [$pattern] is already in the global Git configuration."
            else
                git config --global --add safe.directory "$pattern"
                ECHO_TEXT "Pattern [$pattern] has been added to the global Git configuration."
            fi
        done

        if [ -d "$PROJECT_DIR" ]; then
            cd "$PROJECT_DIR" || return

            if [ -d ".git" ]; then
                git config core.fileMode false
            fi
            cd ../../ || return
        else
            ECHO_INFO "No Git repository found in [$PROJECT_DIR]"
        fi
    fi
}

git_switch_branch() {
    local PROJECT_DIR="${PWD}/$PROJECT_TYPE/$DOMAIN_FULL/"

    yn=$(GET_USER_INPUT "question" "Switch from master branch?")

    case $yn in
    [Yy]*)
        if [ -d "$PROJECT_DIR/.git" ]; then

            default_branch='develop'
            read -rp "$(ECHO_ENTER "Enter branch [default '$default_branch']: ")" user_input
            BRANCH="${user_input:-$default_branch}"

            if git show-ref --quiet --verify "refs/heads/$BRANCH"; then
                ECHO_YELLOW "Switching to branch '$BRANCH'"

                (
                    cd "$PROJECT_DIR" || exit
                    git stash && git switch "$BRANCH"
                )
                cd ../../ || exit
            else
                EMPTY_LINE
                ECHO_YELLOW "Branch '$BRANCH' does not exist."
            fi

        else
            ECHO_YELLOW "Branch '$BRANCH' does not exist."
            ECHO_INFO "No Git repository found in [$PROJECT_DIR]"
        fi
        ;;
    *)
        ECHO_YELLOW "Aborted branch switch."
        ;;
    esac
}
