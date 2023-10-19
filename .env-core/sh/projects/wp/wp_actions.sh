#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

wp_actions() {
	unset_variables "PROJECT_TYPE"

	while true; do
		EMPTY_LINE
		ECHO_CYAN "===== WP actions ===="
		ECHO_YELLOW "0 - Return to main menu"
		ECHO_GREEN "1 - Composer install [theme]"
		ECHO_GREEN "2 - Composer package"
		ECHO_GREEN "3 - Delete site data (posts, themes, plugins)"
		ECHO_GREEN "4 - Into a multisite installation"

		action=$(GET_USER_INPUT "select_one_of")

		case $action in
		0)
			actions_existing_project
			;;
		1)
			wp_composer_install
			unset_variables
			actions_existing_project
			;;
		2)
			wp_composer_package
			unset_variables
			actions_existing_project
			;;
		3)
			wp_site_empty
			unset_variables
			actions_existing_project
			;;
		4)
			wp_multisite_convert
			unset_variables
			actions_existing_project
			;;
		esac
	done
}
