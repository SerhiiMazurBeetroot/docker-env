#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

notice_windows_host() {
    QUESTION=$1

    if [[ $OSTYPE == "windows" ]]; then
        if [[ $QUESTION == "add" ]]; then
            ECHO_INFO "For Windows User"
            ECHO_GREEN "127.0.0.1 $DOMAIN_FULL"
            ECHO_GREEN "kindly add it to your Windows host file"
            ECHO_GREEN "Open file in editor path below (ctrl + click)"
            realpath "C:\Windows\System32\drivers\etc\hosts"
        fi

        if [[ $QUESTION == "rem" ]]; then
            ECHO_INFO "For Windows User"
            ECHO_GREEN "127.0.0.1 $DOMAIN_FULL"
            ECHO_GREEN "please remember to remove it from the host file"
            ECHO_GREEN "Open file in editor path below (ctrl + click)"
            realpath "C:\Windows\System32\drivers\etc\hosts"
        fi
    fi
}

notice_project_urls() {
    EMPTY_LINE
    ECHO_KEY_VALUE "DOMAIN_FULL:" "https://$DOMAIN_FULL"
    [[ $DOMAIN_ADMIN != "" ]] && ECHO_KEY_VALUE "DOMAIN_ADMIN:" "https://$DOMAIN_ADMIN"
    [[ $DOMAIN_ADMIN != "" ]] && ECHO_KEY_VALUE "DOMAIN_DB:" "https://$DOMAIN_DB"
    [[ $DOMAIN_MAIL != "" ]] && ECHO_KEY_VALUE "DOMAIN_MAIL:" "https://$DOMAIN_MAIL"
    EMPTY_LINE
}

notice_project_vars() {
    ECHO_KEY_VALUE "PROJECT_TYPE:" "$PROJECT_TYPE"
    ECHO_KEY_VALUE "DOMAIN_NAME:" "$DOMAIN_NAME"
    notice_project_urls
    notice_windows_project_vars
    ECHO_KEY_VALUE "PHP_VERSION:" "$PHP_VERSION"
    notice_wp_vars

    ECHO_YELLOW "You can find this info in the file /"$PROJECT_DOCKER_DIR"/.env"
    EMPTY_LINE
}

notice_windows_project_vars() {
    if [[ $OSTYPE == "windows" ]]; then
        ECHO_KEY_VALUE "HOST_NAME:" "127.0.0.1 $DOMAIN_FULL"
        realpath "C:\Windows\System32\drivers\etc\hosts"

    fi
}

notice_composer() {
    if [[ $COMPOSER_ISSUE ]]; then
        ECHO_ERROR "There are problems with composer.json"
        ECHO_INFO "Please update composer.json file in your theme."
        ECHO_INFO "Choose Docker actions and update composer"
        EMPTY_LINE
    fi
}

notice_wp_vars() {
    if [[ $PROJECT_TYPE == "wordpress" || $PROJECT_TYPE == "bedrock" ]]; then
        ECHO_KEY_VALUE "WP_VERSION:" "$WP_VERSION"
        ECHO_KEY_VALUE "WP_USER:" "$WP_USER"
        ECHO_KEY_VALUE "WP_PASSWORD:" "$WP_PASSWORD"
        ECHO_KEY_VALUE "DB_NAME:" "$DB_NAME"
        ECHO_KEY_VALUE "TABLE_PREFIX:" "$TABLE_PREFIX"
        [[ $PROJECT_TYPE == "wordpress" ]] && ECHO_KEY_VALUE "MULTISITE:" "$MULTISITE"
    fi
}

notice_compose_v2() {
    docker_compose_version

    if [[ $COMPOSE_VERSION == 1 ]]; then
        ECHO_INFO "Please install docker compose V2."
        ECHO_INFO "Help readme 6.5"
        EMPTY_LINE
    fi
}
