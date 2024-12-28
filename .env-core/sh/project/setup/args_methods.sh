#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

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
            "NODE_VERSION"
        )
        ;;
    'nodejs')
        ARGS=(
            "NODE_VERSION"
        )
        ;;
    'nextjs')
        ARGS=(
            "NODE_VERSION"
        )
        ;;
    'directus' | 'directus_nextjs')
        ARGS=(
            "DB_NAME"
            "DIRECTUS_VERSION"
        )
        ;;
    'elasticsearch')
        ARGS=(
            "ELASTIC_VERSION"
        )
        ;;
    *)
        echo "Unsupported project type: $PROJECT_TYPE"
        ;;
    esac
}

set_custom_args() {
    get_project_args
    local skip_user_input=false

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
            skip_user_input=true
            ;;
        'NODE_VERSION')
            get_nodejs_version
            skip_user_input=true
            ;;
        'DIRECTUS_VERSION')
            get_directus_version
            skip_user_input=true
            ;;
        'ELASTIC_VERSION')
            get_elastic_version
            skip_user_input=true
            ;;
        *)
            echo "Unsupported argument: $arg"
            ;;
        esac

        if [[ "$skip_user_input" != true ]]; then
            # Print user choice

            read -rp "$(ECHO_ENTER "Enter $arg [default '$default_value']")" user_input
            if [[ -n "$user_input" ]]; then
                eval "$arg=\"$user_input\""
            else
                eval "$arg=\"$default_value\""
            fi

            skip_user_input=false
        fi

    done
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
        'NODE_VERSION')
            get_nodejs_version "default"
            ;;
        'DIRECTUS_VERSION')
            get_directus_version "default"
            ;;
        'ELASTIC_VERSION')
            get_elastic_version
            ;;
        *)
            echo "Unsupported argument: $arg"
            ;;
        esac
    done
}

get_project_dir() {
    QUESTION=$1

    get_domain_default_name

    #Beetroot project - DOMAIN_NAME_DEFAULT
    [[ "$SETUP_TYPE" -eq 3 ]] && DOMAIN_NAME_DEFAULT="$DOMAIN_NAME.local"

    #DOMAIN_FULL
    if [[ $QUESTION == "skip_question" ]]; then
        DOMAIN_FULL=$(awk '/'" $DOMAIN_NAME "'/{print $7}' "$FILE_INSTANCES" | head -n 1)
    else
        if [[ $TEST_RUNNING -ne 1 ]]; then
            ECHO_ENTER "Enter DOMAIN_FULL [default $DOMAIN_NAME_DEFAULT]"
            read -rp "DOMAIN_FULL: " DOMAIN_FULL
        fi
    fi

    [[ $DOMAIN_FULL == '' ]] && DOMAIN_FULL="$DOMAIN_NAME_DEFAULT"

    # Remove non printing chars from DOMAIN_FULL
    DOMAIN_FULL=$(echo $DOMAIN_FULL | tr -dc '[[:print:]]' | tr -d ' ' | tr -d '[A' | tr -d '[C' | tr -d '[B' | tr -d '[D')

    # Replace "_" to "-"
    DOMAIN_FULL=$(echo $DOMAIN_FULL | sed 's/_/-/g')

    set_project_vars
}
