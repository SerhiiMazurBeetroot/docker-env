#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

check_env_settings () {
    if [ ! -f ./env-core/settings.log ]; 
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
        ENV_THEME=$(awk '/''/{print $1}' ./env-core/settings.log | tail -n 1);
    fi
}

change_env_theme () {
    ENV_THEME=$(awk '/''/{print $1}' ./env-core/settings.log | tail -n 1);
    ENV_VERSION=$(awk '/''/{print $3}' ./env-core/settings.log | tail -n 1);

    if [ "$ENV_THEME" = 'dark' ];
    then
        save_settings "light"
    else
        save_settings "dark"
    fi
    exit
}

check_env_version () {
    ENV_VERSION=$(awk '/''/{print $3}' ./env-core/settings.log | tail -n 1);
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

    rm ./env-core/settings.log
    echo "ENV_THEME | ENV_VERSION |" >> ./env-core/settings.log
    echo "$ENV_THEME  | $ENV_VERSION   |" >> ./env-core/settings.log
}

update_env () {
    if [ $ENV_VERSION != $GIT_VERSION ];
    then
        ECHO_GREEN "Getting updates..."
        git fetch
        git reset --hard origin/master

        sed -i -e 's/'$ENV_VERSION'/'$GIT_VERSION'/g' ./env-core/settings.log
    else
        ECHO_GREEN "Already up to date."
        EMPTY_LINE
    fi
}

fix_linux_watchers () {
    if [[ $OSTYPE == "linux" ]];
    then
        EMPTY_LINE
        ECHO_YELLOW "Change system limit for number of file watchers"
        echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
    fi
}
