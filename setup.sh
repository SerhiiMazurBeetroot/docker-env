#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

export CORE_VERSION=2.0.4
export ENV_DIR="${DOCKER_ENV_DIR:-.}"

# shellcheck disable=SC1091
source "$ENV_DIR"/.env-core/sh/autoloader.sh

main_actions() {
	healthcheck

	while true; do
		ECHO_CYAN "======== docker-env ======="
		ECHO_YELLOW "0 - Exit and do nothing"
		ECHO_GREEN "1 - Nginx"
		ECHO_GREEN "2 - New project"
		ECHO_GREEN "3 - Existing project"
		ECHO_KEY_VALUE "4 - Settings" "$ENV_UPDATES"
		echo_tests_actions

		userChoice=$(GET_USER_INPUT "select_one_of")

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
		9)
			tests_actions
			;;
		*)
			ECHO_WARN_RED "Invalid selection. Please try again."
			;;
		esac
	done

}

main_actions
