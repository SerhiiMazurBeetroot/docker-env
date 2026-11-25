#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Names of running containers, one per line. One docker call per redraw.
system_running_names() {
	docker ps --format '{{.Names}}' 2>/dev/null || true
}

system_name_running() {
	local name="$1"
	local names="$2"
	grep -qx "$name" <<<"$names"
}

# "up to date" / "update available" / "" from the last update check.
system_updates_hint() {
	case "${ENV_UPDATES:-}" in
	"There is a new version") printf 'update available' ;;
	"Everything up-to-date") printf 'up to date' ;;
	*) printf '' ;;
	esac
}

system_menu() {
	load_system_modules

	while true; do
		local names nginx_up dozzle_up webui_up
		local nginx_hint webui_hint state choice key index
		local -a labels=() keys=() hints=() colors=()

		names=$(system_running_names)
		nginx_up=0 dozzle_up=0 webui_up=0
		system_name_running "nginx-proxy" "$names" && nginx_up=1
		system_name_running "nginx-dozzle" "$names" && dozzle_up=1
		system_name_running "${WEBUI_CONTAINER:-nginx-webui}" "$names" && webui_up=1

		if ((nginx_up && dozzle_up && webui_up)); then
			state="all services running"
		elif ((!nginx_up && !dozzle_up && !webui_up)); then
			state="all services stopped"
		else
			local -a down=()
			((nginx_up)) || down+=("Nginx")
			((dozzle_up)) || down+=("Dozzle")
			((webui_up)) || down+=("Web UI")
			state="$(printf '%s, ' "${down[@]}")"
			state="${state%, } stopped"
		fi

		nginx_hint="$( ((nginx_up)) && printf 'running' || printf 'stopped') · Dozzle $( ((dozzle_up)) && printf 'running' || printf 'stopped')"
		if ((webui_up)); then
			webui_hint="running · $(webui_url)"
			webui_is_dev && webui_hint+=" (dev)"
		else
			webui_hint="stopped"
		fi

		labels+=("Nginx proxy") keys+=("nginx") hints+=("$nginx_hint") colors+=("$GREEN")
		labels+=("Web UI") keys+=("webui") hints+=("$webui_hint") colors+=("$GREEN")
		labels+=("Settings") keys+=("settings") hints+=("$(system_updates_hint)") colors+=("$GREEN")
		if [[ ${ENV_MODE:-} == 'development' ]]; then
			labels+=("Run tests") keys+=("tests") hints+=("dev only") colors+=("$RED")
		fi

		EMPTY_LINE
		menu_header "System · $state"
		ECHO_YELLOW "[0] Main menu"
		for ((index = 0; index < ${#labels[@]}; index++)); do
			menu_row "$((index + 1))" "${labels[$index]}" "${hints[$index]}" "${colors[$index]}"
		done

		choice=$(GET_USER_INPUT "select_one_of")
		if [[ "${choice//[[:space:]]/}" == "0" ]]; then
			return 0
		fi
		key=$(menu_pick_key "$choice" "${keys[@]}")

		case "$key" in
		nginx)
			nginx_menu
			;;
		webui)
			webui_menu
			;;
		settings)
			env_settings
			;;
		tests)
			TEST_MODE=true
			load_system_tests
			tests_actions
			;;
		*)
			ECHO_WARN_RED "Invalid selection. Please try again."
			;;
		esac
	done
}
