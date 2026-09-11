#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_wp() {
	unset_variables
	docker_create_require_nginx || return 1
	setup_installation_type_callback docker_create_wp
	check_domain_exists
	docker_create_require_new_site || return 1
	check_data_before_continue_callback docker_create_wp || return 1

	docker_create_project docker_create_wp_after
}

docker_create_wp_after() {
	wait_for_db
	wp_core_install
	wp_site_empty
	edit_file_compose_setup_beetroot
	edit_file_gitignore
	git_clone_menu
	notice_composer
}
