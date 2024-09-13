#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

primary_menu() {
	while true; do
		ECHO_CYAN "======== docker-env ======="
		ECHO_YELLOW "0 - Exit and do nothing"
		ECHO_GREEN "1 - System Services"
		ECHO_GREEN "2 - New project"
		ECHO_GREEN "3 - Project Services"

		userChoice=$(GET_USER_INPUT "select_one_of")

		case "$userChoice" in
		0)
			exit
			;;
		1)
			system_services_menu
			;;
		2)
			new_project_menu
			;;
		3)
			project_services_menu
			;;
		*)
			ECHO_WARN_RED "Invalid selection. Please try again."
			;;
		esac
	done

}
