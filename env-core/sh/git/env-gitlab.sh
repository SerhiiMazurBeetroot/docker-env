#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

git_save_token_gitlab () {
    #Remove token before save
    gitlab=$(awk '/TOKEN_GITLAB/{print}' "$FILE_SETTINGS");

    read -rp "Gitlab token: " TOKEN_GITLAB
    [[ $gitlab != '' && $TOKEN_GITLAB != '' ]] && sed -i -e '/'"$gitlab"'/d' "$FILE_SETTINGS"
    [[ $TOKEN_GITLAB != '' ]] && echo "TOKEN_GITLAB=$TOKEN_GITLAB" >> "$FILE_SETTINGS"
}

git_save_user_gitlab () {
    #Remove user before save
    gitlab=$(awk '/USER_GITLAB/{print}' "$FILE_SETTINGS");

    read -rp "Gitlab user: " USER_GITLAB
    [[ $gitlab != '' && $USER_GITLAB != '' ]] && sed -i -e '/'"$gitlab"'/d' "$FILE_SETTINGS"
    [[ $USER_GITLAB != '' ]] && echo "USER_GITLAB=$USER_GITLAB" >> "$FILE_SETTINGS"
}

git_create_repo_gitlab () {
    TOKEN_GITLAB=$(awk '/TOKEN_GITLAB/{print $1}' "$FILE_SETTINGS" | sed 's/'TOKEN_GITLAB='//' );
    USER_GITLAB=$(awk '/USER_GITLAB/{print $1}' "$FILE_SETTINGS" | sed 's/'USER_GITLAB='//' );

    [[ $TOKEN_GITLAB == '' ]] && git_save_token_gitlab || true
    [[ $USER_GITLAB == '' ]] && git_save_user_gitlab || true

    if [[ $TOKEN_GITLAB && $USER_GITLAB ]];
    then
        #REPO_TYPE
        EMPTY_LINE
        ECHO_YELLOW "Enter REPO_TYPE [default '1']"
        ECHO_GREEN "1 - Private"
        ECHO_GREEN "2 - Public"
        read -rp "$(ECHO_YELLOW "Please select one of:")" REPO_TYPE

        #REPO_NAME
        REPO_NAME="$DOMAIN_NAME"

        #REPO_TYPE
        [[ $REPO_TYPE == 1 ]] && REPO_TYPE="private"
        [[ $REPO_TYPE == 2 ]] && REPO_TYPE="public"

        response=$(curl --silent --header "PRIVATE-TOKEN: $TOKEN_GITLAB" \
        -XPOST "https://gitlab.com/api/v4/projects?name="$REPO_NAME"&visibility="$REPO_TYPE"")

        response="$(echo $response | awk '/{"message":{"/ {print}' || true )"

        if [[ $response == "" ]];
        then
            ECHO_SUCCESS "Gitlab"

            cd "$PROJECT_ROOT_DIR"

            if [[ -d "${PWD}/.git" ]];
            then
                ECHO_YELLOW "Push Origin Master..."
                git push -u origin master
            else
                ECHO_YELLOW "Creating Repository..."

                git init
                git add .
                git commit -m "initial commit"
                git branch -M master
                git remote add origin https://gitlab-ci-token:${TOKEN_GITLAB}@gitlab.com/$USER_GITLAB/$REPO_NAME.git
                git push -u origin master
            fi

            cd ../../
        else
            ECHO_ERROR "Gitlab: $response"
        fi
    else
        ECHO_ATTENTION "Please fill in your access information"
    fi
}
