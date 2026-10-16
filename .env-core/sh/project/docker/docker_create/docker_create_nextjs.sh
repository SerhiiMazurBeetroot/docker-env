#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_nextjs_after() {
	(cd "$PROJECT_ROOT_DIR" && npm i)
	edit_file_gitignore
}
