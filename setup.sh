#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

export CORE_VERSION=2.0.3
export ENV_DIR="${DOCKER_ENV_DIR:-.}"

# shellcheck disable=SC1091
source "$ENV_DIR"/.env-core/sh/scripts.sh

main_actions() {
	EMPTY_LINE
	healthcheck

	# Notice about updates to main menu
	[[ ! $ENV_UPDATES ]] && check_env_version "daily"
	[[ $ENV_UPDATES == "Everything up-to-date" ]] && ENV_UPDATES=""

	while true; do
		ECHO_INFO "======== docker-env ======="
		ECHO_YELLOW "0 - Exit and do nothing"
		ECHO_GREEN "1 - Nginx"
		ECHO_GREEN "2 - New project"
		ECHO_GREEN "3 - Existing project"
		ECHO_KEY_VALUE "4 - Settings" "$ENV_UPDATES"

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
		esac
	done

}

main_actions
