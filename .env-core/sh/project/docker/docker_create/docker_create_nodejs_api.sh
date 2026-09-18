#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_nodejs_api() {
	unset_variables
	get_domain_name
	check_domain_exists
	docker_create_require_new_site || return 1
	check_data_before_continue_callback docker_create_nodejs_api || return 1

	CREATE_TEMPLATE="nodejs"
	CREATE_NODE_PORTS=1
	CREATE_COMPOSE_CMD="up -d"
	CREATE_SKIP_PERMISSIONS=1
	CREATE_SKIP_DOCKER_RESTART=1
	get_project_dir "skip_question"
	CREATE_COMPOSE_DIR="$PROJECT_ROOT_DIR"
	CREATE_ENV_FILE="$PROJECT_ROOT_DIR/.env"
	docker_create_project
}
