#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

check_env_settings () {
    if [ ! -f "$FILE_SETTINGS" ]; 
    then
        if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == "true" ];
        then
            ENV_VERSION=$(git log -n 1 --pretty=format:"%H")
        else
            echo "# test" >> README.MD
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
        ENV_THEME=$(awk '/''/{print $1}' "$FILE_SETTINGS" | tail -n 1);
    fi
}

change_env_theme () {
    ENV_THEME=$(awk '/ENV_THEME/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_THEME='//' );
    ENV_VERSION=$(awk '/ENV_VERSION/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_VERSION='//' );

    if [ "$ENV_THEME" = 'dark' ];
    then
        save_settings "light"
    else
        save_settings "dark"
    fi
    exit
}

check_env_version () {
    replace_old_settings_file

    ENV_THEME=$(awk '/ENV_THEME/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_THEME='//' );
    ENV_VERSION=$(awk '/ENV_VERSION/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_VERSION='//' );

    REPO='git://github.com/SerhiiMazurBeetroot/devENV.git'
    URL='https://api.github.com/repos/SerhiiMazurBeetroot/devENV'

    if curl --output /dev/null --silent --head --fail -k $URL
    then
        GIT_VERSION=$(git ls-remote $REPO | grep refs/heads/master | cut -f 1);
    else
        GIT_VERSION=$ENV_VERSION
    fi

    if [ $ENV_VERSION != $GIT_VERSION ];
    then
        ENV_UPDATES="There is a new version"
    else
        ENV_UPDATES="Everything up-to-date"
    fi
}

save_settings () {
    ENV_THEME=$1

    [ -f "$FILE_SETTINGS" ] && rm "$FILE_SETTINGS"
    echo "ENV_THEME=$ENV_THEME" >> "$FILE_SETTINGS"
    echo "ENV_VERSION=$ENV_VERSION" >> "$FILE_SETTINGS"
}

update_env () {
    if [ $ENV_VERSION != $GIT_VERSION ];
    then
        ECHO_GREEN "Getting updates..."
        git fetch
        git reset --hard origin/master

        sed -i -e 's/'$ENV_VERSION'/'$GIT_VERSION'/g' "$FILE_SETTINGS"
    else
        ECHO_GREEN "Already up to date."
        EMPTY_LINE
    fi
}

fix_linux_watchers () {
    if [[ $OSTYPE == "linux" ]];
    then
        limit=$(cat /proc/sys/fs/inotify/max_user_watches)
        if [[ "$limit" -lt 524288 ]];
        then
            EMPTY_LINE
            ECHO_YELLOW "Change system limit for number of file watchers"
            echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
        fi
    fi
}
