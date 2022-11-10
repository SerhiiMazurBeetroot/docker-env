#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

env_settings() {
    check_env_version "$@"

    while true; do
        EMPTY_LINE
        ECHO_INFO "===== ENV settings ===="
        ECHO_YELLOW "0 - Return to main menu"
        ECHO_KEY_VALUE "1 - ENV_UPDATES:" "$ENV_UPDATES"
        ECHO_KEY_VALUE "2 - ENV_THEME:" "$ENV_THEME"
        read -rp "$(ECHO_YELLOW "Please select one of:")" settings

        case $settings in
        0)
            main_actions
            ;;
        1)
            update_env
            ;;
        2)
            change_env_theme
            ;;
        esac
    done
}

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
            git remote add origin https://github.com/SerhiiMazurBeetroot/devENV.git
            git fetch
            git reset --hard origin/master

            ENV_VERSION=$(git log -n 1 --pretty=format:"%H")
        fi

        save_settings "dark"
    else
        ENV_THEME=$(awk '/''/{print $1}' "$FILE_SETTINGS" | tail -n 1)
    fi
}

change_env_theme() {
    ENV_THEME=$(awk '/ENV_THEME/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_THEME='//')
    ENV_VERSION=$(awk '/ENV_VERSION/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_VERSION='//')

    if [ "$ENV_THEME" = 'dark' ]; then
        save_settings "light"
    else
        save_settings "dark"
    fi
    exit
}

check_git_version() {
    REPO='https://github.com/SerhiiMazurBeetroot/devENV.git'
    URL='https://api.github.com/repos/SerhiiMazurBeetroot/devENV'

    if curl --output /dev/null --silent --head --fail -k $URL; then
        GIT_VERSION=$(git ls-remote $REPO | grep refs/heads/master | cut -f 1)
    else
        GIT_VERSION=$ENV_VERSION
    fi

    if [[ $ENV_VERSION != $GIT_VERSION ]]; then
        ENV_UPDATES="There is a new version"
    else
        ENV_UPDATES="Everything up-to-date"
    fi
}

check_env_version() {
    env_migration

    ENV_THEME=$(awk '/ENV_THEME/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_THEME='//')
    ENV_VERSION=$(awk '/ENV_VERSION/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_VERSION='//')
    ENV_DATE_CHECK=$(awk '/ENV_DATE_CHECK/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_DATE_CHECK='//')
    DATE_NOW=$(date +'%m/%d/%Y')

    if [[ $ENV_DATE_CHECK == '' ]]; then
        check_git_version

        #First setup
        echo "ENV_DATE_CHECK=$DATE_NOW" >>"$FILE_SETTINGS"
    else
        #Run only once a day
        if [[ $ENV_DATE_CHECK != $DATE_NOW || $1 != 'daily' ]]; then
            check_git_version

            #Replace ENV_DATE_CHECK
            sed -i -e '/ENV_DATE_CHECK/d' "$FILE_SETTINGS"
            echo "ENV_DATE_CHECK=$DATE_NOW" >>"$FILE_SETTINGS"
        fi
    fi
}

save_settings() {
    ENV_THEME=$1

    if [[ -f "$FILE_SETTINGS" ]]; then
        #Replace ENV_THEME
        sed -i -e '/ENV_THEME/d' "$FILE_SETTINGS"
        echo "ENV_THEME=$ENV_THEME" >>"$FILE_SETTINGS"
    else
        echo "ENV_THEME=$ENV_THEME" >>"$FILE_SETTINGS"
        echo "ENV_VERSION=$ENV_VERSION" >>"$FILE_SETTINGS"
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

core_version() {
    if [[ $CORE_VER_CUR == '' ]]; then
        echo "CORE_VERSION=$CORE_VERSION" >>"$FILE_SETTINGS"
    else
        #Replace CORE_VERSION
        sed -i -e '/CORE_VERSION/d' "$FILE_SETTINGS"
        echo "CORE_VERSION=$CORE_VERSION" >>"$FILE_SETTINGS"
    fi
}
