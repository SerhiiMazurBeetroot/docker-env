#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

notice_windows_host () {
    QUESTION=$1

  if [[ $OSTYPE == "windows" ]];
    then
        if [[ $QUESTION == "add" ]];
        then
            ECHO_INFO "For Windows User"
            ECHO_GREEN "127.0.0.1 $DOMAIN_FULL"
            ECHO_GREEN "kindly add it to your Windows host file"
            ECHO_GREEN "Open file in editor path below (ctrl + click)"
            realpath "C:\Windows\System32\drivers\etc\hosts"
        fi

        if [[ $QUESTION == "rem" ]];
        then
            ECHO_INFO "For Windows User"
            ECHO_GREEN "127.0.0.1 $DOMAIN_FULL"
            ECHO_GREEN "please remember to remove it from the host file"
            ECHO_GREEN "Open file in editor path below (ctrl + click)"
            realpath "C:\Windows\System32\drivers\etc\hosts"
        fi
    fi
}

notice_project_vars() {
    ECHO_KEY_VALUE "DOMAIN_NAME:" "$DOMAIN_NAME"
    ECHO_KEY_VALUE "DOMAIN_FULL:" "https://$DOMAIN_FULL"
    ECHO_KEY_VALUE "WP_VERSION:" "$WP_VERSION"
    ECHO_KEY_VALUE "WP_USER:" "$WP_USER"
    ECHO_KEY_VALUE "WP_PASSWORD:" "$WP_PASSWORD"
    ECHO_KEY_VALUE "PHP_VERSION:" "$PHP_VERSION"
    ECHO_KEY_VALUE "DB_NAME:" "$DB_NAME"
    ECHO_KEY_VALUE "TABLE_PREFIX:" "$TABLE_PREFIX"
    ECHO_KEY_VALUE "COMPOSER:" "$COMPOSER"
    ECHO_YELLOW "You can find this info in the file /projects/$DOMAIN_FULL/wp-docker/.env" 
    EMPTY_LINE
}

notice_composer () {
    if [[ $COMPOSER_ISSUE ]];
    then
        ECHO_ERROR "There are problems with composer.json"
        ECHO_INFO "Please update composer.json file in your theme."
        ECHO_INFO "Choose Docker actions and update composer"
        EMPTY_LINE
    fi
}
