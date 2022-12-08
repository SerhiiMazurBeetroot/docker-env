#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

CORE_VERSION=2.0.0

# shellcheck disable=SC1091
source ./.env-core/sh/scripts.sh

main_actions() {
	EMPTY_LINE
	healthcheck

	# Notice about updates to main menu
	[[ ! $ENV_UPDATES ]] && check_env_version "daily"
	[[ $ENV_UPDATES == "Everything up-to-date" ]] && ENV_UPDATES=""

	while true; do
		ECHO_INFO "======== devENV ======="
		ECHO_YELLOW "0 - Exit and do nothing"
		ECHO_GREEN "1 - Nginx"
		ECHO_GREEN "2 - New project"
		ECHO_GREEN "3 - Existing project"
		ECHO_KEY_VALUE "4 - ENV settings" "$ENV_UPDATES"
		ECHO_KEY_VALUE "5"

		read -rp "$(ECHO_YELLOW "Please select one of:")" userChoice

		case "$userChoice" in
		0)
			exit
			;;
		1)
			nginx_actions
			;;
		2)
			actions_new_project
			;;
		3)
			actions_existing_project
			;;
		4)
			env_settings
			;;
		5)
			get_latest_wp_version
			;;
		esac
	done

}

main_actions