#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

healthcheck() {
	check_package_availability
	detect_os
	check_instances_file_exists
	check_env_settings
	protect_settings_file
	load_system_modules
	webui_sync_auth_env || true
	docker_nginx_container
	notice_compose_v2
	env_mode
	load_project_modules
	env_migration
	add_alias
	update_core_env_file
	clear_nginx_logs
	# get_bash_version
}
