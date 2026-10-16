#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Compose already brought the stack up; bouncing Elasticsearch immediately fails
# health and docker_restart's "container exists" check, so the catalog sets
# CREATE_SKIP_DOCKER_RESTART and nginx is reloaded here instead.
docker_create_elastic_after() {
	edit_file_gitignore
	docker_nginx_restart || true
}
