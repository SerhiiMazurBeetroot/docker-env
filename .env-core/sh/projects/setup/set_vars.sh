#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

set_project_vars() {
    get_project_type

    PROJECT_DIR=$PROJECT_TYPE
    DOMAIN_NODOT=$(echo "$DOMAIN_NAME" | tr . _)
    PROJECT_ROOT_DIR="$ENV_DIR"/"$PROJECT_DIR"/"$DOMAIN_FULL"
    PROJECT_ARCHIVE_DIR=$PROJECT_DIR"_""$DOMAIN_FULL"

    # Set default variables
    DOMAIN_NAME_DEFAULT="dev.$DOMAIN_NAME.local"
    DOMAIN_DB=""
    DOCKER_VOLUME_DB="$DOMAIN_NAME"_db_data
    DOCKER_CONTAINER_DB="$DOMAIN_NAME-mysql"
    PROJECT_DOCKER_DIR="$PROJECT_ROOT_DIR/docker"
    PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/database
    DB_TYPE="0"
    DB_NAME="db"
    DOMAIN_FRONT=""
    DOMAIN_ADMIN=""
    DOMAIN_MAIL=""

    PROJECT_BACKEND_DIR=$PROJECT_ROOT_DIR/backend
    PROJECT_FRONTEND_DIR=$PROJECT_ROOT_DIR/frontend

    if [[ -z "$PORT_FRONT" ]]; then
        PORT_FRONT=0
    fi

    get_compose_project_name

    case $PROJECT_TYPE in
    "wordpress" | "projects")
        DB_TYPE="MYSQL"
        DOMAIN_ADMIN="$DOMAIN_FULL/wp-admin"
        PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/wp-docker
        PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/wp-database
        PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/wp-content
        DOCKER_CONTAINER_APP="$DOMAIN_NAME-wordpress"
        DOMAIN_DB="$DOMAIN_FULL.phpmyadmin"
        DOMAIN_MAIL="$DOMAIN_FULL.mail"
        HOST_EXTRA="$DOMAIN_DB $DOMAIN_MAIL"
        ;;
    "bedrock")
        DB_TYPE="MYSQL"
        DOMAIN_ADMIN="$DOMAIN_FULL/wp/wp-admin"
        PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/app/web/app
        DOCKER_CONTAINER_APP="$DOMAIN_NAME-bedrock"
        DOMAIN_DB="$DOMAIN_FULL.phpmyadmin"
        DOMAIN_MAIL="$DOMAIN_FULL.mail"
        HOST_EXTRA="$DOMAIN_DB $DOMAIN_MAIL"
        ;;
    "php")
        PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/app
        DOCKER_CONTAINER_APP="$DOMAIN_NAME-php"
        ;;
    "wpnextjs")
        DB_TYPE="MYSQL"
        PROJECT_DATABASE_DIR=$PROJECT_BACKEND_DIR/wp-database
        PROJECT_WP_CONTENT_DIR=$PROJECT_BACKEND_DIR/wp-content
        DOMAIN_ADMIN="$DOMAIN_FULL/wp-admin"
        DOCKER_CONTAINER_APP="$DOMAIN_NAME-wpnextjs"
        ;;
    "nodejs")
        DB_TYPE="MONGO"
        PROJECT_DIR="nodejs"
        DOCKER_CONTAINER_APP="$DOMAIN_NAME-nodejs"
        DOCKER_CONTAINER_DB="$DOMAIN_NAME-mongo"
        ;;
    "nextjs")
        DOCKER_CONTAINER_APP="$DOMAIN_NAME-nextjs"
        ;;
    "directus")
        DB_TYPE="POSTGRES"
        DB_NAME="directus"
        DOMAIN_DB="$DOMAIN_FULL.pgadmin"
        DOCKER_CONTAINER_DB="$DOMAIN_NAME-postgres"
        DOCKER_CONTAINER_APP="$DOMAIN_NAME-directus"
        HOST_EXTRA="$DOMAIN_DB"
        ;;
    "directus_nextjs")
        DB_TYPE="POSTGRES"
        ;;
    "elasticsearch")
        DOMAIN_LOGSTASH="$DOMAIN_FULL.logstash"
        DOMAIN_KIBANA="$DOMAIN_FULL.kibana"
        DOCKER_CONTAINER_APP="$DOMAIN_NAME-elastic"
        HOST_EXTRA="$DOMAIN_LOGSTASH $DOMAIN_KIBANA"
        ;;
    *)
        echo "Unknown PROJECT_TYPE: $PROJECT_TYPE"
        return 1
        ;;
    esac

    if [ "$HOST_EXTRA" ]; then
        HOST_EXTRA="$DOMAIN_DB $DOMAIN_MAIL"
    fi
}
