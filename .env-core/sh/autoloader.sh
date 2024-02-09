#!/bin/bash

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
