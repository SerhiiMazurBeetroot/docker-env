#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_directus_nextjs_after() {
	mkdir -p "$PROJECT_ROOT_DIR/backend/uploads" "$PROJECT_ROOT_DIR/backend/extensions"
}
