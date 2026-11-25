#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Start replaces the old Setup + Start pair.
# First run (no certificates yet) goes through docker_nginx_setup, which also hands
# certs-root to the current user with sudo. Later starts only make sure the shared
# volume and network exist, so a plain start never asks for a password.
nginx_menu_start() {
	if [[ ! -d "${DIR_NGINX:-}/certs-root" ]]; then
		docker_nginx_setup
		return
	fi

	docker volume inspect ssl-certs >/dev/null 2>&1 || docker volume create --name ssl-certs >/dev/null
	docker network inspect dockerwp >/dev/null 2>&1 || docker network create dockerwp >/dev/null
	docker_nginx_start
}

nginx_menu_reset_ssl() {
	local yn
	yn=$(GET_USER_INPUT "question" "Delete the local SSL certificates and set Nginx up again? Browsers will need to trust the new CA." "n")
	if [[ ! "$yn" =~ ^[Yy]$ ]]; then
		ECHO_INFO "Cancelled"
		return 0
	fi
	docker_nginx_resetup
}

nginx_menu() {
	while true; do
		local dozzle choice key index
		local -a labels=() keys=() hints=() colors=()

		docker_nginx_container
		if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "nginx-dozzle"; then
			dozzle="running"
		else
			dozzle="stopped"
		fi

		if [[ "${NGINX_EXISTS:-0}" -eq 1 ]]; then
			labels+=("Restart") keys+=("restart") hints+=("") colors+=("$GREEN")
			labels+=("Stop") keys+=("stop") hints+=("") colors+=("$GREEN")
			labels+=("Rebuild") keys+=("rebuild") hints+=("recreate the containers") colors+=("$GREEN")
			labels+=("Reset SSL") keys+=("reset") hints+=("deletes certificates, then sets up again") colors+=("$RED")
		else
			labels+=("Start") keys+=("start") hints+=("") colors+=("$GREEN")
			labels+=("Rebuild") keys+=("rebuild") hints+=("recreate the containers") colors+=("$GREEN")
		fi

		EMPTY_LINE
		menu_header "Nginx proxy · $([[ "${NGINX_EXISTS:-0}" -eq 1 ]] && printf 'running' || printf 'stopped')"
		ECHO_KEY_VALUE "Dozzle logs:" "http://127.0.0.1:7007 ($dozzle)"
		ECHO_YELLOW "[0] System"
		for ((index = 0; index < ${#labels[@]}; index++)); do
			menu_row "$((index + 1))" "${labels[$index]}" "${hints[$index]}" "${colors[$index]}"
		done

		choice=$(GET_USER_INPUT "select_one_of")
		if [[ "${choice//[[:space:]]/}" == "0" ]]; then
			return 0
		fi
		key=$(menu_pick_key "$choice" "${keys[@]}")

		case "$key" in
		start)
			nginx_menu_start
			;;
		stop)
			docker_nginx_stop
			;;
		restart)
			docker_nginx_restart
			;;
		rebuild)
			docker_nginx_rebuild
			;;
		reset)
			nginx_menu_reset_ssl
			;;
		*)
			ECHO_WARN_RED "Invalid selection. Please try again."
			;;
		esac
	done
}
