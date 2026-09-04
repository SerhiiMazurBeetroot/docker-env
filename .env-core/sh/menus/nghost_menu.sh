#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

nghost_menu() {
	docker_nginx_container

	while true; do
		EMPTY_LINE
		ECHO_CYAN "======= NgHost ========"
		ECHO_YELLOW "0 - Return to main menu"
		ECHO_GREEN "1 - Setup"
		ECHO_GREEN "2 - Stop"
		ECHO_GREEN "3 - Start"
		ECHO_GREEN "4 - Restart"
		ECHO_GREEN "5 - Rebuild"

		proxy_actions=$(GET_USER_INPUT "select_one_of")

		case $proxy_actions in
		0)
			main_actions
			;;
		1)
			docker_nghost_setup
			;;
		2)
			docker_nghost_stop
			;;
		3)
			docker_nghost_start
			;;
		4)
			docker_nghost_restart
			;;
		5)
			docker_nghost_rebuild
			;;
		esac
	done
}
