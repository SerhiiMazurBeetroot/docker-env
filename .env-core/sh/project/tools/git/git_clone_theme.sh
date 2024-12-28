#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

git_clone_theme() {
    get_existing_domains
    check_domain_exists

    if [[ $DOMAIN_EXISTS == 1 ]]; then
        case $PROJECT_TYPE in
        "wordpress" | "bedrock" | "wpnextjs")
            git_can_clone "Getting themes from the repository"

            THEME_NAME=$(basename "$URL_CORRECT" .git)

            choice=$(GET_USER_INPUT "enter" "Enter THEME_NAME [default '$THEME_NAME']")

            if [ -n "$choice" ]; then
                THEME_NAME="$choice"
            fi

            if [ -d "$PROJECT_ROOT_DIR/wp-content/themes/$THEME_NAME" ]; then
                TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
                THEME_NAME="$THEME_NAME"_"$TIMESTAMP"
            fi

            if [[ $CAN_CLONE == 1 ]]; then
                ECHO_YELLOW "Cloning theme repository to temp..."
                rm -rf $PROJECT_ROOT_DIR/repository

                git config --global http.sslVerify false

                git clone "$URL_CLONE" $PROJECT_ROOT_DIR/repository/themes/

                ECHO_INFO "Please wait, copying themes..."

                if [ -d $PROJECT_ROOT_DIR/repository/themes ]; then
                    cp -rf $PROJECT_ROOT_DIR/repository/themes/. $PROJECT_ROOT_DIR/wp-content/themes/$THEME_NAME
                fi

                rm -rf $PROJECT_ROOT_DIR/repository
                ECHO_YELLOW "Theme copied, THEME_NAME: $THEME_NAME"
                EMPTY_LINE
            fi

            CAN_CLONE=0
            ;;
        *)
            ECHO_ERROR "The site is not WP"
            ;;
        esac
    else
        ECHO_ERROR "Docker container doesn't exist [$PROJECT_ROOT_DIR]"
    fi

    unset_variables "PROJECT_TYPE"
}
