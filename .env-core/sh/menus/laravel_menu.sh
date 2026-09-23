#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

laravel_menu() {
	load_project_modules

	while true; do
		EMPTY_LINE
		ECHO_CYAN "===== Laravel ===="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] Artisan command"
		ECHO_GREEN "[2] Migrate"
		ECHO_GREEN "[3] Migrate fresh"
		ECHO_GREEN "[4] Clear caches"
		ECHO_GREEN "[5] Storage link"
		ECHO_GREEN "[6] Composer require"

		action=$(GET_USER_INPUT "select_one_of")

		case $action in
		0)
			return 0
			;;
		1)
			laravel_artisan_prompt
			;;
		2)
			laravel_artisan migrate --force
			;;
		3)
			laravel_migrate_fresh
			;;
		4)
			laravel_artisan optimize:clear
			;;
		5)
			laravel_artisan storage:link
			;;
		6)
			laravel_composer_require
			;;
		esac
	done
}
