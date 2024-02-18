#!/bin/bash

# shellcheck disable=SC1091
export DIR_DATA="$ENV_DIR/.env-core/data"
export DIR_NGINX="$ENV_DIR/.env-core/nginx"

export FILE_SETTINGS="$DIR_DATA/settings.log"
export FILE_INSTANCES="$DIR_DATA/instances.log"
export FILE_DOCKER_HUB="$DIR_DATA/dockerHub.log"

export ALIAS_CMD="docker-env"
export GITHUB_USER="SerhiiMazurBeetroot"
export OLD_REPO="$GITHUB_USER/devENV"
export MAIN_REPO="$GITHUB_USER/docker-env"
export TEMPLATES_REPO="https://github.com/$GITHUB_USER/docker-env-template"
