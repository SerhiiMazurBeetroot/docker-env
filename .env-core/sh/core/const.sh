#!/bin/bash

# shellcheck disable=SC1091
export DIR_DATA="$ENV_DIR/.env-core/data"
export DIR_NGINX="$ENV_DIR/.env-core/nginx"

export FILE_SETTINGS="$DIR_DATA/settings.log"
export FILE_INSTANCES="$DIR_DATA/instances.log"
export FILE_DOCKER_HUB="$DIR_DATA/dockerHub.log"

export ALIAS_CMD="docker-env"
export OLD_REPO="SerhiiMazurBeetroot/devENV"
export MAIN_REPO="SerhiiMazurBeetroot/docker-env"
