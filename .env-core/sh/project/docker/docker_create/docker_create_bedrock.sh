#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_bedrock_after() {
	# run.sh composer create-project fills the empty app volume; do not chmod while it runs.
	wait_for_wp_core || return 1
	wait_for_db
	fix_permissions
	wp_core_install
	wp_site_empty
	docker_restart
}
