#!/bin/bash

# shellcheck disable=SC1091
export DIR_DATA="$ENV_DIR/.env-core/data"
export DIR_NGINX="$ENV_DIR/.env-core/nginx" # reassign [env_migration]
export DIR_SYSTEM="$ENV_DIR/.env-core/system"

export FILE_SETTINGS="$DIR_DATA/settings.log"
export FILE_INSTANCES="$DIR_DATA/instances.log"
export FILE_DOCKER_HUB="$DIR_DATA/dockerHub.log"
export FILE_ENV="$DIR_SYSTEM/.env"

export ALIAS_CMD="docker-env"
export GITHUB_USER="SerhiiMazurBeetroot"
export OLD_REPO="$GITHUB_USER/devENV"
export MAIN_REPO="$GITHUB_USER/docker-env"
export TEMPLATES_REPO="https://github.com/$GITHUB_USER/docker-env-template"

export ENV_UPDATES=""
export TEST_RUNNING=0
export DOMAIN_NAME=""
export SETUP_TYPE="0"
export PORT_FRONT=""
export ARGS=""
export DOMAIN_EXISTS=0
export DB_NAME=""
export TABLE_PREFIX=""
export WP_VERSION=""
export WP_USER=""
export WP_PASSWORD=""
export EMPTY_CONTENT="1"
export MULTISITE=""
export PHP_VERSION=""
export NODE_VERSION=""
export NEXTJS_VERSION=""
export DIRECTUS_VERSION=""
export ELASTIC_VERSION=""
export passw=""
export SETUP_ACTION=""
export PROJECT_TYPE=""
export DOCKER_CONTAINER_DB=""
export DOCKER_CONTAINER_APP=""
export PROJECT_ROOT_DIR=""
