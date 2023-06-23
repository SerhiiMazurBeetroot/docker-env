#!/bin/bash

# shellcheck disable=SC1091
DIR_DATA="$ENV_DIR/.env-core/data"
DIR_NGINX="$ENV_DIR/.env-core/nginx"

FILE_SETTINGS="$DIR_DATA/settings.log"
FILE_INSTANCES="$DIR_DATA/instances.log"
FILE_DOCKER_HUB="$DIR_DATA/dockerHub.log"

export AVAILABLE_PROJECTS=(wordpress bedrock php nodejs wpnextjs)

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
