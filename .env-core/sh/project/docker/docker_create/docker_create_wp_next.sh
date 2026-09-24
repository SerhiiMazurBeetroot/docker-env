#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_wp_next() {
	unset_variables
	docker_create_require_nginx || return 1
	get_domain_name
	check_domain_exists
	docker_create_require_new_site || return 1
	get_project_dir "$@"
	set_project_args
	check_data_before_continue_callback docker_create_wp_next || return 1

	CREATE_TEMPLATE="wordpress_nextjs"
	docker_create_project docker_create_wp_next_after
}

docker_create_wp_next_after() {
	mkdir -p \
		"$PROJECT_ROOT_DIR/wp-content/uploads" \
		"$PROJECT_ROOT_DIR/wp-content/themes" \
		"$PROJECT_ROOT_DIR/wp-content/plugins" \
		"$PROJECT_ROOT_DIR/logs/wordpress"
	wp_core_install
	wp_site_empty
}
