#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

env_migration() {
	local CORE_VER_CUR
	CORE_VER_CUR=$(awk -F= '/CORE_VERSION/{print $2}' "$FILE_SETTINGS" | tr -d '[:space:]')

	move_dir_data

	if [[ -n "$CORE_VER_CUR" ]]; then
		case "$CORE_VER_CUR" in
		"1.0.0")
			#case v.1.0.0 => v.2.0.0
			replace_old_settings_file
			replace_wp_instances_file_1_0
			replace_dir_projects_to_wordpress
			replace_docker_compose
			delete_visible_envcore_dir
			;;
		"2.0.0")
			replace_wp_instances_file_2_0
			;;
		esac

		if [[ $CORE_VER_CUR < '2.0.3' ]]; then
			fix_old_compose_project_name
		fi
	fi

	# case start v.2.0.1
	env_update_repo
	core_version
}

move_dir_data() {
	if [ -f "$ENV_DIR/.env-core/instances.log" ]; then
		ECHO_YELLOW "Replacing FILE_INSTANCES ..."

		mv "$ENV_DIR/.env-core/settings.log" $FILE_SETTINGS
		mv "$ENV_DIR/.env-core/instances.log" $FILE_INSTANCES
	fi
}

delete_visible_envcore_dir() {
	if [ -d "env-core" ]; then
		rm -rf env-core
	fi
}
