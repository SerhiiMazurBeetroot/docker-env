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

# BASH_VERSION 3.2.57 (default macOS)
export PROJECT_TITLES=(
  "Wordpress"
  "BEDROCK"
  "PHP-Server"
  "Next.js"
  "Next.WP"
  "Node.js"
)

export AVAILABLE_PROJECTS=(
  "wordpress"
  "bedrock"
  "php"
  "nextjs"
)

source_files_in() {
  local dir="$1"

  if [[ -r "$dir" && -x "$dir" ]]; then
    for file in "$dir"/*; do
      if [[ -f "$file" && -r "$file" ]]; then
        . "$file"
      elif [[ -d "$file" ]]; then
        source_files_in "$file"
      fi
    done
  fi
}

source_files_in "$ENV_DIR/.env-core/sh/utils"
source_files_in "$ENV_DIR/.env-core/sh/core"
source_files_in "$ENV_DIR/.env-core/sh/nginx"
source_files_in "$ENV_DIR/.env-core/sh/projects"
source_files_in "$ENV_DIR/.env-core/sh/tests"
