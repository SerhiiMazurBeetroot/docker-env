#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_wp_next_after() {
	mkdir -p \
		"$PROJECT_ROOT_DIR/wp-content/uploads" \
		"$PROJECT_ROOT_DIR/wp-content/themes" \
		"$PROJECT_ROOT_DIR/wp-content/plugins" \
		"$PROJECT_ROOT_DIR/logs/wordpress"
	wp_core_install
	wp_site_empty
}
