#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_bedrock() {
	unset_variables
	docker_create_require_nginx || return 1
	setup_installation_type_callback docker_create_bedrock
	check_domain_exists
	docker_create_require_new_site || return 1
	check_data_before_continue_callback docker_create_bedrock || return 1

	CREATE_SKIP_DOCKER_RESTART=1
	CREATE_SKIP_PERMISSIONS=1
	docker_create_project docker_create_bedrock_after
}

docker_create_bedrock_after() {
	# run.sh composer create-project fills the empty app volume; do not chmod while it runs.
	wait_for_wp_core || return 1
	wait_for_db
	fix_permissions
	wp_core_install
	wp_site_empty
	docker_restart
}
