#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_wp_after() {
	wait_for_db
	wp_core_install
	wp_site_empty
	edit_file_compose_setup_beetroot
	edit_file_gitignore
	git_clone_menu
	notice_composer
}
