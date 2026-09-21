#!/bin/bash

# shellcheck disable=SC1091
export DIR_DATA="$ENV_DIR/.env-core/data"
export DIR_SYSTEM="$ENV_DIR/.env-core/system"
export DIR_NGINX="$DIR_SYSTEM/nginx"

export FILE_SETTINGS="$DIR_DATA/settings.log"
export FILE_INSTANCES="$DIR_DATA/instances.log"
export FILE_DOCKER_HUB="$DIR_DATA/dockerHub.log"
export FILE_ENV="$DIR_SYSTEM/.env"
export FILE_WEBUI_PID="$DIR_DATA/webui.pid"
export FILE_WEBUI_LOG="$DIR_DATA/webui.log"

export WEBUI_HOST="127.0.0.1"
export WEBUI_PORT="7777"
export WEBUI_CONTAINER="nginx-webui"

export ALIAS_CMD="docker-env"
export GITHUB_USER="SerhiiMazurBeetroot"
export OLD_REPO="$GITHUB_USER/devENV"
export MAIN_REPO="$GITHUB_USER/docker-env"
export TEMPLATES_REPO="https://github.com/$GITHUB_USER/docker-env-template"

export ENV_UPDATES=""
export ENV_MODE=""
export ENV_THEME="dark"
export ENV_VERSION=""
export GIT_VERSION=""
export ENV_DATE_CHECK=""
export ENV_CORE_INITIALIZED=0
export ENV_PROJECT_LOADED=0
export ENV_SYSTEM_LOADED=0
export ENV_TESTS_LOADED=0

export TEST_RUNNING=0
export TEST_MODE=""

# --- Session / wizard state (reset via reset_session_var, never unset under nounset) ---
export DOMAIN_NAME=""
export DOMAIN_FULL=""
export SETUP_TYPE="0"
export PORT=""
export PORT_FRONT=""
export COMPOSE_PROJECT_NAME=""
export MONGODB_LOCAL_PORT=""
export MONGODB_DOCKER_PORT=""
export MONGO_EXPRESS_PORT=""
export ELASTIC_PORT=""
export KIBANA_PORT=""
export LOGSTASH_PORT=""
export DOMAIN_EXISTS=0
export DB_NAME=""
export DB_TYPE="0"
export TABLE_PREFIX=""
export WP_VERSION=""
export WP_USER=""
export WP_PASSWORD=""
export WP_DEFAULT_THEME=""
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
export INSTANCES_STATUS=""

# --- Resolved project paths (set by set_project_vars / get_project_dir) ---
export DOCKER_CONTAINER_DB=""
export DOCKER_CONTAINER_APP=""
export DOCKER_VOLUME_DB=""
export DOCKER_COMPOSE_CMD="docker compose"
export COMPOSE_VERSION=""
export NGINX_EXISTS=0
export DOCKER_IP=""

export PROJECT_ROOT_DIR=""
export PROJECT_DOCKER_DIR=""
export PROJECT_DATABASE_DIR=""
export PROJECT_WP_CONTENT_DIR=""

# --- Runtime DB helpers (not passed to docker compose interpolation) ---
export MYSQL_CMD=""
export MYSQL_DUMP_CMD=""
export MYSQL_ADMIN_CMD=""
export DB_FILE=""
export DB_EXISTS=""
export CAN_CLONE=0
export URL_CLONE=""
export COMPOSER_ISSUE=""

export CREATE_TEMPLATE=""
export CREATE_COMPOSE_CMD=""
export CREATE_COMPOSE_DIR=""
export CREATE_ENV_FILE=""
export CREATE_SYNC_PORT_FRONT=0
export CREATE_NODE_PORTS=0
export CREATE_SKIP_PERMISSIONS=0
export CREATE_SKIP_DOCKER_RESTART=0

export WP_LATEST_VER=""
export WP_PREV_VER=""

# Bash 3.2 arrays (not exported)
TESTS_PROJECT_TYPES=()
