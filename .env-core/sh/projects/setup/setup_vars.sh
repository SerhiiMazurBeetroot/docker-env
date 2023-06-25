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
        EMPTY_LINE
        ECHO_YELLOW "Enter DOMAIN_FULL [default $DOMAIN_NAME_DEFAULT]"
        read -rp "DOMAIN_FULL: " DOMAIN_FULL
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
    *)
        echo "Unknown PROJECT_TYPE: $PROJECT_TYPE"
        return 1
        ;;
    esac
}

set_wordpress_vars() {
    #WP
    DB_TYPE="MYSQL"
    DOMAIN_ADMIN="$DOMAIN_FULL/wp-admin"
    DOMAIN_DB="$DOMAIN_FULL.phpmyadmin"
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/wp-docker
    PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/wp-database
    PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/wp-content
    DOCKER_CONTAINER_APP="$DOMAIN_NAME-wordpress"
    DOCKER_CONTAINER_DB="$DOMAIN_NAME-mysql"
    DOCKER_VOLUME_DB="$DOMAIN_NAME"_db_data
    HOST_EXTRA="$DOMAIN_FULL.phpmyadmin"
}

set_bedrock_vars() {
    #BEDROCK
    DB_TYPE="MYSQL"
    DOMAIN_ADMIN="$DOMAIN_FULL/wp/wp-admin"
    DOMAIN_DB="$DOMAIN_FULL.phpmyadmin"
    DOMAIN_MAIL="$DOMAIN_FULL.mail"
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/docker
    PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/database
    PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/app/web/app
    DOCKER_CONTAINER_APP="$DOMAIN_NAME-bedrock"
    DOCKER_CONTAINER_DB="$DOMAIN_NAME-mysql"
    DOCKER_VOLUME_DB="$DOMAIN_NAME"_db_data
    HOST_EXTRA="$DOMAIN_FULL.phpmyadmin $DOMAIN_FULL.mail"
}

set_php_vars() {
    #php
    DB_TYPE="MYSQL"
    DOMAIN_ADMIN=""
    DOMAIN_DB=""
    DOMAIN_MAIL=""
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/docker
    PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/database
    PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/app
    DOCKER_CONTAINER_APP="$DOMAIN_NAME-php"
    DOCKER_CONTAINER_DB="$DOMAIN_NAME-mysql"
    DOCKER_VOLUME_DB="$DOMAIN_NAME"_db_data
    HOST_EXTRA=""
}

set_wpnextjs_vars() {
    #WP-Next
    DB_TYPE="MYSQL"
    DB_NAME="db"
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/docker
    PROJECT_BACKEND_DIR=$PROJECT_ROOT_DIR/backend
    PROJECT_FRONTEND_DIR=$PROJECT_ROOT_DIR/frontend
    PROJECT_DATABASE_DIR=$PROJECT_BACKEND_DIR/wp-database
    PROJECT_WP_CONTENT_DIR=$PROJECT_BACKEND_DIR/wp-content
    DOMAIN_ADMIN="$DOMAIN_FULL/wp-admin"
    DOMAIN_DB="$DOMAIN_FULL.phpmyadmin"
    DOCKER_CONTAINER_APP="$DOMAIN_NAME-wpnextjs"
    DOCKER_CONTAINER_DB="$DOMAIN_NAME-mysql"
    DOCKER_VOLUME_DB="$DOMAIN_NAME"_db_data
    HOST_EXTRA="$DOMAIN_FULL.phpmyadmin"
}

set_nodejs_vars() {
    #nodejs
    DB_TYPE="MONGO"
    DB_NAME="db"
    PROJECT_DIR="nodejs"
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/docker
    PROJECT_BACKEND_DIR=$PROJECT_ROOT_DIR/backend
    PROJECT_FRONTEND_DIR=$PROJECT_ROOT_DIR/frontend
    DOCKER_CONTAINER_APP="$DOMAIN_NAME-nodejs"
    DOCKER_CONTAINER_DB="$DOMAIN_NAME-mongo"
    DOCKER_VOLUME_DB="$DOMAIN_NAME"_db_data
    HOST_EXTRA=""
}

get_compose_project_name() {
    if [ -n "$DOMAIN_FULL" ]; then
        COMPOSE_PROJECT_NAME=$(echo "$DOMAIN_FULL" | sed "s/[^a-zA-Z0-9_\-]/_/g; s/^-//; s/-$/_/; s/-/_/g; s/[^a-zA-Z0-9_\-]//g; s/^$/none/")
    fi
}
