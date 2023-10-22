#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

get_project_type() {
    if [[ "$PROJECT_TYPE" == '' ]]; then
        PROJECT_TYPE=$(awk '/'"$DOMAIN_NAME"'/{print $13}' "$FILE_INSTANCES" | head -n 1)
    fi
}

get_project_dir() {
    QUESTION=$1

    DOMAIN_NAME_DEFAULT="dev.$DOMAIN_NAME.local"

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

set_project_vars() {
    get_project_type

    PROJECT_DIR=$PROJECT_TYPE
    DOMAIN_NODOT=$(echo "$DOMAIN_NAME" | tr . _)
    PROJECT_ROOT_DIR="$ENV_DIR"/"$PROJECT_DIR"/"$DOMAIN_FULL"
    PROJECT_ARCHIVE_DIR=$PROJECT_DIR"_""$DOMAIN_FULL"

    set_default_vars
    get_compose_project_name

    case $PROJECT_TYPE in
    "wordpress" | "projects")
        set_wordpress_vars
        ;;
    "bedrock")
        set_bedrock_vars
        ;;
    "php")
        set_php_vars
        ;;
    "wpnextjs")
        set_wpnextjs_vars
        ;;
    "nodejs")
        set_nodejs_vars
        ;;
    "nextjs")
        set_nextjs_vars
        ;;
    *)
        echo "Unknown PROJECT_TYPE: $PROJECT_TYPE"
        return 1
        ;;
    esac
}

set_default_vars() {
    DOMAIN_DB="$DOMAIN_FULL.phpmyadmin"
    DOMAIN_MAIL="$DOMAIN_FULL.mail"
    DOCKER_VOLUME_DB="$DOMAIN_NAME"_db_data
    DOCKER_CONTAINER_DB="$DOMAIN_NAME-mysql"
    DB_TYPE="MYSQL"
    PORT_FRONT=0
}

set_wordpress_vars() {
    #WP
    DOMAIN_ADMIN="$DOMAIN_FULL/wp-admin"
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/wp-docker
    PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/wp-database
    PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/wp-content
    DOCKER_CONTAINER_APP="$DOMAIN_NAME-wordpress"
    HOST_EXTRA="$DOMAIN_DB $DOMAIN_MAIL"
}

set_bedrock_vars() {
    #BEDROCK
    DOMAIN_ADMIN="$DOMAIN_FULL/wp/wp-admin"
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/docker
    PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/database
    PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/app/web/app
    DOCKER_CONTAINER_APP="$DOMAIN_NAME-bedrock"
    HOST_EXTRA="$DOMAIN_DB $DOMAIN_MAIL"
}

set_php_vars() {
    #php
    DOMAIN_ADMIN=""
    DB_NAME="0"
    DOMAIN_MAIL=""
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/docker
    PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/database
    PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/app
    DOCKER_CONTAINER_APP="$DOMAIN_NAME-php"
    HOST_EXTRA=""
}

set_wpnextjs_vars() {
    #WP-Next
    DB_NAME="db"
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/docker
    PROJECT_BACKEND_DIR=$PROJECT_ROOT_DIR/backend
    PROJECT_FRONTEND_DIR=$PROJECT_ROOT_DIR/frontend
    PROJECT_DATABASE_DIR=$PROJECT_BACKEND_DIR/wp-database
    PROJECT_WP_CONTENT_DIR=$PROJECT_BACKEND_DIR/wp-content
    DOMAIN_ADMIN="$DOMAIN_FULL/wp-admin"
    DOCKER_CONTAINER_APP="$DOMAIN_NAME-wpnextjs"
    HOST_EXTRA="$DOMAIN_DB $DOMAIN_MAIL"
}

set_nodejs_vars() {
    #nodejs
    DB_TYPE="MONGO"
    DB_NAME="db"
    DOMAIN_MAIL=""
    PROJECT_DIR="nodejs"
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/docker
    PROJECT_BACKEND_DIR=$PROJECT_ROOT_DIR/backend
    PROJECT_FRONTEND_DIR=$PROJECT_ROOT_DIR/frontend
    DOCKER_CONTAINER_APP="$DOMAIN_NAME-nodejs"
    DOCKER_CONTAINER_DB="$DOMAIN_NAME-mongo"
    HOST_EXTRA=""
}

set_nextjs_vars() {
    #Next.js
    DB_TYPE="0"
    DB_NAME="0"
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/docker
    DOCKER_CONTAINER_APP="$DOMAIN_NAME-nextjs"
    DOMAIN_ADMIN=""
    DOMAIN_MAIL=""
    HOST_EXTRA=""
}

get_compose_project_name() {
    if [ -n "$DOMAIN_FULL" ]; then
        COMPOSE_PROJECT_NAME=$(echo "$DOMAIN_FULL" | sed "s/[^a-zA-Z0-9_\-]/_/g; s/^-//; s/-$/_/; s/-/_/g; s/[^a-zA-Z0-9_\-]//g; s/^$/none/")
    fi
}
