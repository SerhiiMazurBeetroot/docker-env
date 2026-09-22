#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

webui_menu() {
	load_system_modules

	while true; do
		EMPTY_LINE
		ECHO_CYAN "======== Web UI ======="
		ECHO_KEY_VALUE "Status" "$(webui_status_label)"
		ECHO_YELLOW "[0] Return to previous menu"
		ECHO_GREEN "[1] Start"
		ECHO_GREEN "[2] Stop"
		ECHO_GREEN "[3] Open in browser"
		if [[ ${ENV_MODE:-} == "development" ]]; then
			ECHO_RED "[4] Rebuild image"
			ECHO_GREEN "[5] Develop image"
		fi

		actions=$(GET_USER_INPUT "select_one_of")
		actions="${actions//$'\r'/}"
		actions="${actions#"${actions%%[![:space:]]*}"}"
		actions="${actions%"${actions##*[![:space:]]}"}"

		case "$actions" in
		0)
			system_menu
			;;
		1)
			webui_server_start
			;;
		2)
			webui_server_stop
			;;
		3)
			if webui_server_is_running; then
				ECHO_INFO "$(webui_url)"
				webui_open_browser
			else
				ECHO_ERROR "Web UI is not running"
			fi
			;;
		4)
			if [[ ${ENV_MODE:-} == "development" ]]; then
				webui_server_rebuild
			else
				ECHO_WARN_RED "Invalid selection. Please try again."
			fi
			;;
		5)
			if [[ ${ENV_MODE:-} == "development" ]]; then
				webui_server_develop
			else
				ECHO_WARN_RED "Invalid selection. Please try again."
			fi
			;;
		*)
			ECHO_WARN_RED "Invalid selection. Please try again."
			;;
		esac
	done
}
