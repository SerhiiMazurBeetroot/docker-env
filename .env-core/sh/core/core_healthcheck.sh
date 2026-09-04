#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

healthcheck() {
	check_package_availability
	detect_os
	check_instances_file_exists
	check_env_settings
	docker_nginx_container
	notice_compose_v2
	env_mode
	env_check_updates
	update_core_env_file
	clear_nginx_logs
	# get_bash_version
}
