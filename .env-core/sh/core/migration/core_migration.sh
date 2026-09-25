#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

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
		"2.0.4")
			update_system_2_0_8
			;;
		esac

		if [[ $CORE_VER_CUR < '2.0.3' ]]; then
			fix_old_compose_project_name
		fi
	fi

	# Numeric compare. The old `<` check above is lexicographic and stays as-is.
	if version_lt "${CORE_VER_CUR:-0}" "3.0.0" || { [[ -f "$FILE_INSTANCES_LOG" ]] && [[ ! -s "$FILE_INSTANCES" ]]; }; then
		migrate_instances_log_to_json
	fi

	export DIR_NGINX="$ENV_DIR/.env-core/system/nginx"

	# case start v.2.0.1
	env_update_repo
	core_version
}

# True when $1 is a lower dotted version than $2 (2.0.8 < 3.0.0).
version_lt() {
	local left="${1:-0}"
	local right="${2:-0}"
	local IFS=.
	local -a a b
	local i n ai bi

	# shellcheck disable=SC2206
	a=($left)
	# shellcheck disable=SC2206
	b=($right)
	n=${#a[@]}
	((${#b[@]} > n)) && n=${#b[@]}

	for ((i = 0; i < n; i++)); do
		ai=${a[i]:-0}
		bi=${b[i]:-0}
		ai=${ai//[^0-9]/}
		bi=${bi//[^0-9]/}
		ai=${ai:-0}
		bi=${bi:-0}
		if ((10#$ai < 10#$bi)); then
			return 0
		fi
		if ((10#$ai > 10#$bi)); then
			return 1
		fi
	done
	return 1
}

move_dir_data() {
	if [ -f "$ENV_DIR/.env-core/instances.log" ]; then
		ECHO_YELLOW "Replacing FILE_INSTANCES ..."

		mkdir -p "$DIR_DATA"
		[[ -f "$ENV_DIR/.env-core/settings.log" ]] && mv "$ENV_DIR/.env-core/settings.log" "$FILE_SETTINGS"
		mv "$ENV_DIR/.env-core/instances.log" "$FILE_INSTANCES_LOG"
	fi
}

delete_visible_envcore_dir() {
	if [ -d "env-core" ]; then
		rm -rf env-core
	fi
}
