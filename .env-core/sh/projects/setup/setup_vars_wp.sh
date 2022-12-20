#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

setup_default_args() {
    #DB_NAME
    [[ $DB_NAME == '' ]] && DB_NAME="db"

    #TABLE_PREFIX
    [[ $TABLE_PREFIX == '' ]] && TABLE_PREFIX="wp_"

    #WP_VERSION
    EMPTY_LINE
    [[ $WP_VERSION == '' ]] && get_latest_wp_version
    if [[ $WP_VERSION ]]; then
        true
    elif [[ ! $WP_VERSION ]]; then
        WP_VERSION=$WP_LATEST_VER
    else
        ECHO_ERROR "Wordpress not supported, please check version"
    fi

    #WP_USER
    [[ $WP_USER == '' ]] && WP_USER=developer

    #WP_PASSWORD
    [[ $passw == '' ]] && randpassword

    if [[ ! "$passw" =~ [1-3] ]]; then
        WP_PASSWORD=1
    elif [[ "$passw" -eq 1 ]]; then
        WP_PASSWORD=1
    elif [[ "$passw" -eq 2 ]]; then
        WP_PASSWORD="$WP_PASSWORD"
    fi

    #EMPTY_CONTENT
    if [[ ! "$EMPTY_CONTENT" =~ [1-2] ]]; then
        EMPTY_CONTENT="no"
    elif [[ "$EMPTY_CONTENT" -eq 1 ]]; then
        EMPTY_CONTENT="no"
    elif [[ "$EMPTY_CONTENT" -eq 2 ]]; then
        EMPTY_CONTENT="yes"
    elif [[ $EMPTY_CONTENT == '' ]]; then
        EMPTY_CONTENT="no"
    fi

    #WP_TYPE
    if [[ ! "$MULTISITE" =~ [1-2] ]]; then
        MULTISITE="no"
    elif [[ "$MULTISITE" -eq 1 ]]; then
        MULTISITE="no"
    elif [[ "$MULTISITE" -eq 2 ]]; then
        MULTISITE="yes"
    elif [[ $MULTISITE == '' ]]; then
        MULTISITE="no"
    fi

    #PHP_VERSION
    get_php_versions "default"

    #Check official image
    local IMAGE="wordpress:$WP_VERSION-php$PHP_VERSION-apache"
    [[ $PROJECT_TYPE -eq 3 || $PROJECT_TYPE == 'php'  ]] && IMAGE="php:$PHP_VERSION-apache"
    [[ $PROJECT_TYPE -eq 2 || $PROJECT_TYPE == 'bedrock'  ]] && IMAGE="php:$PHP_VERSION-apache"

    docker_official_image_exists $IMAGE
}

setup_custom_args() {
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
    ECHO_KEY_VALUE "[1]" "1"
    ECHO_KEY_VALUE "[2]" "$WP_PASSWORD"
    ECHO_KEY_VALUE "[3]" "Enter your password"
    read -rp "$(ECHO_YELLOW "Please select one of:")" passw
    if [[ "$passw" -eq 3 ]]; then
        EMPTY_LINE
        read -rp "$(ECHO_YELLOW "Your password:")" WP_PASSWORD
    fi

    #Remove default content
    EMPTY_LINE
    ECHO_YELLOW "EMPTY_CONTENT [default 'no']"
    ECHO_GREEN "1 - no"
    ECHO_GREEN "2 - yes"
    read -rp "$(ECHO_YELLOW "Please select one of:")" EMPTY_CONTENT

    #WP_TYPE
    EMPTY_LINE
    ECHO_YELLOW "Do you want a multisite installation? [default 'no']"
    randpassword
    ECHO_KEY_VALUE "[1]" "no"
    ECHO_KEY_VALUE "[2]" "yes"
    read -rp "$(ECHO_YELLOW "Please select one of:")" MULTISITE

    #PHP_VERSION
    EMPTY_LINE
    ECHO_YELLOW "Enter PHP_VERSION [default 2nd item]"
    get_php_versions

    setup_default_args
}
