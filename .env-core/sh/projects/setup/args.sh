#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

set_custom_args() {
    get_project_args

    for arg in "${ARGS[@]}"; do
        case $arg in
        'DB_NAME')
            default_value="db"
            ;;
        'TABLE_PREFIX')
            default_value="wp_"
            ;;
        'WP_VERSION')
            get_latest_wp_version
            default_value="$WP_LATEST_VER"
            ;;
        'WP_USER')
            default_value="developer"
            ;;
        'WP_PASSWORD')
            randpassword
            default_value="1"
            ;;
        'EMPTY_CONTENT')
            default_value="no"
            ;;
        'MULTISITE')
            default_value="single"
            ;;
        'PHP_VERSION')
            get_php_versions
            default_value=""
            ;;
        *)
            echo "Unsupported argument: $arg"
            ;;
        esac

        EMPTY_LINE
        read -rp "$(ECHO_YELLOW "Enter $arg [default '$default_value']")" user_input
        if [[ -n "$user_input" ]]; then
            eval "$arg=\"$user_input\""
        else
            eval "$arg=\"$default_value\""
        fi
    done

    get_project_args
}

get_project_args() {
    case $PROJECT_TYPE in
    'wordpress')
        ARGS=(
            "DB_NAME"
            "TABLE_PREFIX"
            "WP_VERSION"
            "WP_USER"
            "WP_PASSWORD"
            "EMPTY_CONTENT"
            "MULTISITE"
            "PHP_VERSION"
        )
        ;;
    'bedrock')
        ARGS=(
            "DB_NAME"
            "TABLE_PREFIX"
            "WP_VERSION"
            "WP_USER"
            "WP_PASSWORD"
            "EMPTY_CONTENT"
            "MULTISITE"
            "PHP_VERSION"
        )
        ;;
    'php')
        ARGS=(
            "PHP_VERSION"
        )
        ;;
    'wpnextjs')
        ARGS=(
            "DB_NAME"
            "TABLE_PREFIX"
            "WP_VERSION"
            "WP_USER"
            "WP_PASSWORD"
            "EMPTY_CONTENT"
            "MULTISITE"
            "PHP_VERSION"
        )
        ;;
    'nodejs')
        ARGS=(
        )
        ;;
    'nextjs')
        ARGS=(
        )
        ;;
    *)
        echo "Unsupported project type: $PROJECT_TYPE"
        ;;
    esac
}

set_project_args() {
    get_project_args

    for arg in "${ARGS[@]}"; do
        case $arg in
        'DB_NAME')
            DB_NAME=${DB_NAME:-"db"}
            ;;
        'TABLE_PREFIX')
            TABLE_PREFIX=${TABLE_PREFIX:-"wp_"}
            ;;
        'WP_VERSION')
            [[ $WP_VERSION == '' ]] && get_latest_wp_version
            if [[ $WP_VERSION ]]; then
                true
            elif [[ -z $WP_VERSION ]]; then
                WP_VERSION=$WP_LATEST_VER
            else
                echo "WordPress not supported, please check version"
            fi
            ;;
        'WP_USER')
            WP_USER=${WP_USER:-"developer"}
            ;;
        'WP_PASSWORD')
            [[ $passw == '' ]] && randpassword

            if [[ ! "$passw" =~ [1-3] ]]; then
                WP_PASSWORD=1
            elif [[ "$passw" -eq 1 ]]; then
                WP_PASSWORD=1
            elif [[ "$passw" -eq 2 ]]; then
                WP_PASSWORD="$WP_PASSWORD"
            fi
            ;;
        'EMPTY_CONTENT')
            if [[ ! "$EMPTY_CONTENT" =~ [1-2] ]]; then
                EMPTY_CONTENT="no"
            elif [[ "$EMPTY_CONTENT" -eq 1 ]]; then
                EMPTY_CONTENT="no"
            elif [[ "$EMPTY_CONTENT" -eq 2 ]]; then
                EMPTY_CONTENT="yes"
            elif [[ $EMPTY_CONTENT == '' ]]; then
                EMPTY_CONTENT="no"
            fi
            ;;
        'MULTISITE')
            if [[ ! "$MULTISITE" =~ [1-2] ]]; then
                MULTISITE="no"
            elif [[ "$MULTISITE" -eq 1 ]]; then
                MULTISITE="no"
            elif [[ "$MULTISITE" -eq 2 ]]; then
                MULTISITE="yes"
            elif [[ $MULTISITE == '' ]]; then
                MULTISITE="no"
            fi
            ;;
        'PHP_VERSION')
            get_php_versions "default"
            ;;
        *)
            echo "Unsupported argument: $arg"
            ;;
        esac
    done
}
