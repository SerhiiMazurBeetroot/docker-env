#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Recursively source *.sh under a directory. Optional skip_dir skips one subfolder name.
source_files_in() {
	local dir="$1"
	local skip_dir="${2:-}"

	if [[ -r "$dir" && -x "$dir" ]]; then
		for file in "$dir"/*; do
			local base
			base=$(basename "$file")

			if [[ -n "$skip_dir" && -d "$file" && "$base" == "$skip_dir" ]]; then
				continue
			fi

			if [[ -f "$file" && -r "$file" ]]; then
				. "$file"
			elif [[ -d "$file" ]]; then
				source_files_in "$file" "$skip_dir"
			fi
		done
	fi
}

_env_boot_mode() {
	if [[ -n "${ENV_MODE:-}" ]]; then
		printf '%s' "$ENV_MODE"
		return 0
	fi

	if [[ -f "$FILE_SETTINGS" ]]; then
		awk -F= '/^ENV_MODE=/{print $2; exit}' "$FILE_SETTINGS"
	fi
}

load_project_modules() {
	if [[ ${ENV_PROJECT_LOADED:-0} -eq 1 ]]; then
		return 0
	fi

	source_files_in "$ENV_DIR/.env-core/sh/project"
	export ENV_PROJECT_LOADED=1
}

load_system_modules() {
	if [[ ${ENV_SYSTEM_LOADED:-0} -eq 1 ]]; then
		return 0
	fi

	local skip_dir=""
	if [[ $(_env_boot_mode) != "development" ]]; then
		skip_dir="tests"
	fi

	source_files_in "$ENV_DIR/.env-core/sh/system" "$skip_dir"
	export ENV_SYSTEM_LOADED=1
}

load_system_tests() {
	if [[ ${ENV_TESTS_LOADED:-0} -eq 1 ]]; then
		return 0
	fi

	# shellcheck disable=SC1091
	source "${ENV_DIR}/.env-core/sh/system/tests/tests_helpers.sh"
	# shellcheck disable=SC1091
	source "${ENV_DIR}/.env-core/sh/system/tests/tests_actions.sh"
	# shellcheck disable=SC1091
	source "${ENV_DIR}/.env-core/sh/system/tests/tests_new_projects.sh"
	export ENV_TESTS_LOADED=1
}
