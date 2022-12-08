#!/bin/bash

# shellcheck disable=SC1091
FILE_SETTINGS='./.env-core/settings.log'
FILE_INSTANCES='./.env-core/instances.log'

export AVAILABLE_PROJECTS=(wordpress bedrock php nodejs)

source_files_in() {
  local dir="$1"

  if [[ -d "$dir" && -r "$dir" && -x "$dir" ]]; then
    for file in "$dir"/*; do
      [[ -f "$file" && -r "$file" ]] && . "$file"
    done
  fi
}

source_files_in "./.env-core/sh/utils"
source_files_in "./.env-core/sh/core"
source_files_in "./.env-core/sh/nginx"
source_files_in "./.env-core/sh/projects/actions"
source_files_in "./.env-core/sh/projects/archives"
source_files_in "./.env-core/sh/projects/database"
source_files_in "./.env-core/sh/projects/docker"
source_files_in "./.env-core/sh/projects/setup"
source_files_in "./.env-core/sh/projects/git"
source_files_in "./.env-core/sh/projects/instances"
source_files_in "./.env-core/sh/projects/wp"
