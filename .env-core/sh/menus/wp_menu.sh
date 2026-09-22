#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

wp_menu() {
	unset_variables "PROJECT_TYPE"

	while true; do
		EMPTY_LINE
		ECHO_CYAN "===== WP Workflow ===="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] Composer install [theme]"
		ECHO_GREEN "[2] Composer package"
		ECHO_GREEN "[3] Delete site data (posts, themes, plugins)"
		ECHO_GREEN "[4] Into a multisite installation"

		action=$(GET_USER_INPUT "select_one_of")

		case $action in
		0)
			return 0
			;;
		1)
			wp_composer_install
			unset_variables
			project_services_menu
			;;
		2)
			wp_composer_package
			unset_variables
			project_services_menu
			;;
		3)
			wp_site_empty
			unset_variables
			project_services_menu
			;;
		4)
			wp_multisite_convert
			unset_variables
			project_services_menu
			;;
		esac
	done
}
