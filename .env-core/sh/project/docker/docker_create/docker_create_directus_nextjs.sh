#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_directus_nextjs() {
	unset_variables
	project_require_nginx_for_type || return 1
	get_domain_name
	check_domain_exists
	docker_create_require_new_site || return 1
	get_project_dir "$@"
	set_project_args
	check_data_before_continue_callback docker_create_directus_nextjs || return 1

	CREATE_TEMPLATE="directus_nextjs"
	docker_create_project docker_create_directus_nextjs_after
}

docker_create_directus_nextjs_after() {
	mkdir -p "$PROJECT_ROOT_DIR/backend/uploads" "$PROJECT_ROOT_DIR/backend/extensions"
}
