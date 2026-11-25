#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

webui_menu() {
	load_system_modules

	while true; do
		local running=0 state choice key index
		local -a labels=() keys=() hints=() colors=()

		if webui_server_is_running; then
			running=1
			state="running"
			webui_is_dev && state+=" (dev)"
		else
			state="stopped"
		fi

		if ((running)); then
			labels+=("Open in browser") keys+=("open") hints+=("") colors+=("$GREEN")
			labels+=("Stop") keys+=("stop") hints+=("") colors+=("$GREEN")
		else
			labels+=("Start") keys+=("start") hints+=("") colors+=("$GREEN")
		fi
		labels+=("Sign-in token") keys+=("token") hints+=("show the token for the login page") colors+=("$GREEN")
		if [[ ${ENV_MODE:-} == "development" ]]; then
			labels+=("Rebuild image") keys+=("rebuild") hints+=("dev only · production image") colors+=("$RED")
			labels+=("Develop mode") keys+=("develop") hints+=("dev only · live reload from source") colors+=("$GREEN")
		fi

		EMPTY_LINE
		menu_header "Web UI · $state"
		((running)) && ECHO_GREEN "$(webui_url)"
		ECHO_YELLOW "[0] System"
		for ((index = 0; index < ${#labels[@]}; index++)); do
			menu_row "$((index + 1))" "${labels[$index]}" "${hints[$index]}" "${colors[$index]}"
		done

		choice=$(GET_USER_INPUT "select_one_of")
		choice="${choice//$'\r'/}"
		if [[ "${choice//[[:space:]]/}" == "0" ]]; then
			return 0
		fi
		key=$(menu_pick_key "$choice" "${keys[@]}")

		case "$key" in
		start)
			webui_server_start
			;;
		stop)
			webui_server_stop
			;;
		open)
			ECHO_INFO "$(webui_url)"
			webui_open_browser
			;;
		token)
			webui_show_token
			;;
		rebuild)
			webui_server_rebuild
			;;
		develop)
			webui_server_develop
			;;
		*)
			ECHO_WARN_RED "Invalid selection. Please try again."
			;;
		esac
	done
}
