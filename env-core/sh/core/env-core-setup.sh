#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

check_all_data () {
    EMPTY_LINE
    ECHO_YELLOW "Check everything before proceeding:"

    while true; do
       print_project_vars

        read -rp "Is that correct? [Y/n] " yn

        case $yn in
        [Yy]*)
            break
            ;;
        [Nn]*)
            ECHO_ERROR "Enter correct information"
            unset_variables
            docker_wp_create
            ;;

        *) echo "Please answer yes or no" ;;
        esac
    done
}

set_setup_type () {
    unset_variables

    EMPTY_LINE
    while true; do
        ECHO_INFO "== Installation type =="
        ECHO_YELLOW "[0] Return to main menu"
        ECHO_KEY_VALUE "[1]" "default"
        ECHO_KEY_VALUE "[2]" "custom"
        ECHO_KEY_VALUE "[3]" "beetroot"
        read -rp "$(ECHO_YELLOW "Please select one of:")" SETUP_TYPE

        case $SETUP_TYPE in
        0)
            main_actions
            ;;
        1)
            get_domain_name
            get_project_dir "$@"
            setup_default_args
            break
            ;;
        2)
            get_domain_name
            get_project_dir "$@"
            setup_custom_args "$@"
            break
            ;;
        3)
            setup_beetroot_args "$@"
            break
            ;;
        esac
    done
}

setup_default_args () {
    #DB_NAME
    [[ $DB_NAME == '' ]] && DB_NAME="db"

    #TABLE_PREFIX
    [[ $TABLE_PREFIX == '' ]] && TABLE_PREFIX="wp_"

    #WP_VERSION
    EMPTY_LINE
    get_latest_wp_version
    if [[ $WP_VERSION ]];
    then
        true
    elif [[ ! $WP_VERSION ]];
    then
        WP_VERSION=$WP_LATEST_VER
    else
        ECHO_ERROR "Wordpress not supported, please check version"
    fi

    #WP_USER
    [[ $WP_USER == '' ]] && WP_USER=developer

    #WP_PASSWORD
    randpassword
    if [[ ! "$passw" =~ [1-3] ]];
    then
        WP_PASSWORD=1
    elif [[ "$passw" -eq 1 ]];
    then
        WP_PASSWORD=1
    elif [[ "$passw" -eq 2 ]];
    then
        WP_PASSWORD="$WP_PASSWORD"
    elif [[ "$passw" -eq 3 ]];
    then
        EMPTY_LINE
        read -rp "$(ECHO_YELLOW "Your password:")" WP_PASSWORD
    fi

    #PHP_VERSION
    get_php_versions "default"

    #COMPOSER
    if [[ ! "$COMPOSER" =~ [1-2] ]];
    then
        COMPOSER="no"
    elif [[ "$COMPOSER" -eq 1 ]];
    then
        COMPOSER="no"
    elif [[ "$COMPOSER" -eq 2 ]];
    then
        COMPOSER="yes"
    fi
}

setup_custom_args () {
    #DB_NAME
    EMPTY_LINE
    ECHO_YELLOW "Enter DB_NAME [default 'db']"
    read -rp "DB_NAME: " DB_NAME

    #TABLE_PREFIX
    EMPTY_LINE
    ECHO_YELLOW "Enter DB TABLE_PREFIX, [default 'wp_']" 
    read -rp "DB TABLE_PREFIX: " TABLE_PREFIX

    #WP_VERSION
    EMPTY_LINE
    get_latest_wp_version
    ECHO_YELLOW "Enter WP_VERSION [default $WP_LATEST_VER]" 
    read -rp "WP_VERSION: " WP_VERSION

    #WP_USER
    EMPTY_LINE
    ECHO_YELLOW "Enter WP_USER [default 'developer']"
    read -rp "WP_USER: " WP_USER

    #WP_PASSWORD
    EMPTY_LINE
    ECHO_YELLOW "Enter WP_PASSWORD [default '1']"
    randpassword
    ECHO_GREEN "1 - 1"
    ECHO_GREEN "2 - $WP_PASSWORD"
    ECHO_GREEN "3 - Enter your password"
    read -rp "$(ECHO_YELLOW "Please select one of:")" passw

    #PHP_VERSION
    EMPTY_LINE
    ECHO_YELLOW "Enter PHP_VERSION [default 2nd item]" 
    get_php_versions

    #COMPOSER
    EMPTY_LINE
    ECHO_YELLOW "Install Composer [default 'no']"
    randpassword
    ECHO_GREEN "1 - no"
    ECHO_GREEN "2 - yes"
    read -rp "$(ECHO_YELLOW "Please select one of:")" COMPOSER

    setup_default_args
}

setup_beetroot_args() {
    EMPTY_LINE
    while true; do
        ECHO_INFO "==== Use variables ===="
        ECHO_YELLOW "[0] Return to main menu"
        ECHO_KEY_VALUE "[1]" "default"
        ECHO_KEY_VALUE "[2]" "custom"
        read -rp "$(ECHO_YELLOW "Please select one of:")" choise

        case $choise in
        0)
            main_actions
            ;;
        1)
            get_domain_name
            get_project_dir "$@"
            setup_default_args
            break
            ;;
        2)
            get_domain_name
            get_project_dir "$@"
            setup_custom_args
            break
            ;;
        esac
    done
}
