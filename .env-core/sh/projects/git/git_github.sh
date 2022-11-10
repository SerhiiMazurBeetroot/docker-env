#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

git_save_token_github() {
    #Remove token before save
    github=$(awk '/TOKEN_GITHUB/{print}' "$FILE_SETTINGS")

    read -rp "Github token: " TOKEN_GITHUB
    [[ $github != '' && $TOKEN_GITHUB != '' ]] && sed -i -e '/'"$github"'/d' "$FILE_SETTINGS"
    [[ $TOKEN_GITHUB != '' ]] && echo "TOKEN_GITHUB=$TOKEN_GITHUB" >>"$FILE_SETTINGS"
}

git_save_user_github() {
    #Remove user before save
    github=$(awk '/USER_GITHUB/{print}' "$FILE_SETTINGS")

    read -rp "Github user: " USER_GITHUB
    [[ $github != '' && $USER_GITHUB != '' ]] && sed -i -e '/'"$github"'/d' "$FILE_SETTINGS"
    [[ $USER_GITHUB != '' ]] && echo "USER_GITHUB=$USER_GITHUB" >>"$FILE_SETTINGS"
}

git_create_repo_github() {
    TOKEN_GITHUB=$(awk '/TOKEN_GITHUB/{print $1}' "$FILE_SETTINGS" | sed 's/'TOKEN_GITHUB='//')
    USER_GITHUB=$(awk '/USER_GITHUB/{print $1}' "$FILE_SETTINGS" | sed 's/'USER_GITHUB='//')

    [[ $TOKEN_GITHUB == '' ]] && git_save_token_github || true
    [[ $USER_GITHUB == '' ]] && git_save_user_github || true

    if [[ $TOKEN_GITHUB && $USER_GITHUB ]]; then
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

        response=$(
            curl -i -X POST https://api.github.com/user/repos \
                -H "Authorization: token $TOKEN_GITHUB" \
                -d @- <<EOF
{
  "name": "$REPO_NAME",
  "description": "Project $REPO_NAME",
  "$REPO_TYPE": "true"
}
EOF
        )

        response="$(echo $response | awk -F'[][]' '{print $2}' | grep -Po '("message": ".*")' | sed 's/"message"://g' || true)"

        if [[ $response == "" ]]; then
            ECHO_SUCCESS "Github"

            cd "$PROJECT_ROOT_DIR"

            if [[ -d "${PWD}/.git" ]]; then
                ECHO_YELLOW "Push Origin Master..."
                git push -u origin master
            else
                ECHO_YELLOW "Creating Repository..."

                git init
                git add .
                git commit -m "initial commit"
                git branch -M master
                git remote add origin https://${TOKEN_GITHUB}@github.com/$USER_GITHUB/$REPO_NAME.git
                git push -u origin master
            fi

            cd ../../
        else
            ECHO_ERROR "Github: $response"
        fi
    else
        ECHO_ATTENTION "Please fill in your access information"
    fi
}
