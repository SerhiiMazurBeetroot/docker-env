#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

get_project_type() {
    if [[ "$PROJECT_TYPE" == '' ]]; then
        PROJECT_TYPE=$(awk '/'"$DOMAIN_NAME"'/{print $13}' "$FILE_INSTANCES" | head -n 1)
    fi

    if [[ $PROJECT_TYPE -eq 1 || "$PROJECT_TYPE" == '' ]]; then
        PROJECT_TYPE="wordpress"
        DB_TYPE="MYSQL"
    elif [[ $PROJECT_TYPE -eq 2 ]]; then
        PROJECT_TYPE="bedrock"
        DB_TYPE="MYSQL"
    elif [[ $PROJECT_TYPE -eq 3 ]]; then
        PROJECT_TYPE="php"
        DB_TYPE="MYSQL"
    elif [[ $PROJECT_TYPE -eq 4 ]]; then
        PROJECT_TYPE="nodejs"
        DB_TYPE="MONGO"
        DB_NAME="db"
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
    PROJECT_ROOT_DIR=$PROJECT_DIR/"$DOMAIN_FULL"
    PROJECT_ARCHIVE_DIR=$PROJECT_DIR"_""$DOMAIN_FULL"

    if [[ $PROJECT_TYPE -eq 1 || $PROJECT_TYPE == 'wordpress' || $PROJECT_TYPE == 'projects' ]]; then
        #WP
        DOMAIN_ADMIN="$DOMAIN_FULL/wp-admin"
        DOMAIN_DB="$DOMAIN_FULL.phpmyadmin"
        PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/wp-docker
        PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/wp-database
        PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/wp-content
        DOCKER_CONTAINER_APP="$DOMAIN_NAME-wordpress"
        DOCKER_CONTAINER_DB="$DOMAIN_NAME-mysql"
        DOCKER_VOLUME_DB="$DOMAIN_NAME"_db_data
        HOST_EXTRA="$DOMAIN_FULL.phpmyadmin"
    elif [[ $PROJECT_TYPE -eq 2 || $PROJECT_TYPE == 'bedrock' ]]; then
        #BEDROCK
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
    elif [[ $PROJECT_TYPE -eq 3 || $PROJECT_TYPE == 'php' ]]; then
        #php
        DOMAIN_ADMIN=""
        DOMAIN_DB=""
        DOMAIN_MAIL=""
        PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/docker
        PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/database
        PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/app
        DOCKER_CONTAINER_APP="$DOMAIN_NAME-php"
        DOCKER_CONTAINER_DB="$DOMAIN_NAME-mysql"
        DOCKER_VOLUME_DB="$DOMAIN_NAME"_db_datac
        HOST_EXTRA=""
    elif [[ $PROJECT_TYPE -eq 4 || $PROJECT_TYPE == 'nodejs' ]]; then
        PROJECT_DIR="nodejs"
        PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR
        HOST_EXTRA=""
    fi

    # EMPTY_LINE
}
