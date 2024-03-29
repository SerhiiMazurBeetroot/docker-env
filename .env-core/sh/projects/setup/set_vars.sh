#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

set_default_vars() {
    DOMAIN_DB="$DOMAIN_FULL.phpmyadmin"
    DOMAIN_MAIL="$DOMAIN_FULL.mail"
    DOCKER_VOLUME_DB="$DOMAIN_NAME"_db_data
    DOCKER_CONTAINER_DB="$DOMAIN_NAME-mysql"
    DB_TYPE="MYSQL"

    if [[ -z "$PORT_FRONT" ]]; then
        PORT_FRONT=0
    fi
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
    DOMAIN_DB=""
}

set_directus_vars() {
    #Directus
    DOMAIN_ADMIN=""
    DB_NAME="directus"
    DOMAIN_FRONT=""
    DOMAIN_DB="$DOMAIN_FULL.pgadmin"
    DOCKER_CONTAINER_DB="$DOMAIN_NAME-postgres"
    DB_TYPE="POSTGRES"
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/docker
    PROJECT_BACKEND_DIR=$PROJECT_ROOT_DIR/backend
    PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/database
    DOCKER_CONTAINER_APP="$DOMAIN_NAME-directus"
    DOMAIN_MAIL=""
    HOST_EXTRA="$DOMAIN_DB"
}

set_directus_nextjs_vars() {
    #Directus
    DOMAIN_ADMIN=""
    DOMAIN_FRONTEND=$DOMAIN_FULL.frontend
    DB_NAME="directus"
    DOMAIN_FRONT=""
    PROJECT_DOCKER_DIR=$PROJECT_ROOT_DIR/docker
    PROJECT_BACKEND_DIR=$PROJECT_ROOT_DIR/backend
    PROJECT_FRONTEND_DIR=$PROJECT_ROOT_DIR/frontend
    PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/database
    DOCKER_CONTAINER_APP="$DOMAIN_NAME-directus"
    HOST_EXTRA="$DOMAIN_DB $DOMAIN_FRONTEND"
}
