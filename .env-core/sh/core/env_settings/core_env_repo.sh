#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

check_env_settings() {
    if [ ! -f "$FILE_SETTINGS" ]; then

        if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ]; then
            ENV_VERSION=$(git log -n 1 --pretty=format:"%H")
        else
            echo "# test" >>README.MD
            git init
            git add README.MD
            git commit -m "first commit"
            git branch -M master
            git remote add origin https://github.com/$MAIN_REPO.git
            git fetch
            git reset --hard origin/master

            ENV_VERSION=$(git log -n 1 --pretty=format:"%H")
        fi

        save_settings "ENV_THEME=dark"

    else
        ENV_THEME=$(awk '/''/{print $1}' "$FILE_SETTINGS" | tail -n 1)
    fi
}

check_git_version() {
    REPO='https://github.com/'$MAIN_REPO'.git'

    if repo_exists "$MAIN_REPO"; then
        # false: Repository does not exist / Error connection.
        GIT_VERSION=$ENV_VERSION
    else
        # true
        GIT_VERSION=$(git ls-remote $REPO | grep refs/heads/master | cut -f 1)
    fi

    if [[ $ENV_VERSION != $GIT_VERSION ]]; then
        ENV_UPDATES="There is a new version"
    else
        ENV_UPDATES="Everything up-to-date"
    fi
}

update_env() {
    if [ $ENV_VERSION != $GIT_VERSION ]; then
        ECHO_GREEN "Getting updates..."
        git fetch
        git reset --hard origin/master

        sed -i -e 's/'$ENV_VERSION'/'$GIT_VERSION'/g' "$FILE_SETTINGS"

        exit
    else
        ECHO_GREEN "Already up to date."
        EMPTY_LINE
    fi
}

repo_exists() {
    local repo_name=$1
    local response=$(curl -s -o /dev/null -w "%{http_code}" "https://api.github.com/repos/$repo_name")

    if [[ $response -eq 200 ]]; then
        return 1
    else
        return 0
    fi
}
