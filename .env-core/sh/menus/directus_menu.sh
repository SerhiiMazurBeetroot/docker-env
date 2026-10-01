#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

directus_menu() {
	load_project_modules

	while true; do
		EMPTY_LINE
		ECHO_CYAN "===== Directus ===="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] Bootstrap"
		ECHO_GREEN "[2] Database migrate"
		ECHO_GREEN "[3] Logs"

		local action yn
		action=$(GET_USER_INPUT "select_one_of")

		case "${action:-0}" in
		0)
			return 0
			;;
		1)
			yn=$(GET_USER_INPUT "question" "Run directus bootstrap on ${DOMAIN_NAME:-this site}?" "n")
			if [[ ! "$yn" =~ ^[Yy]$ ]]; then
				ECHO_INFO "Cancelled"
			else
				directus_exec bootstrap
			fi
			;;
		2)
			directus_exec database migrate:latest
			;;
		3)
			site_container_logs "$(directus_container_name)"
			;;
		*)
			ECHO_WARN_RED "Wrong option"
			;;
		esac
	done
}
