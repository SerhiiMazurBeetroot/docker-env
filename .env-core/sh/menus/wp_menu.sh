#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

wp_menu() {
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
			;;
		2)
			wp_composer_package
			;;
		3)
			wp_site_empty ask
			;;
		4)
			wp_multisite_convert
			;;
		esac
	done
}
