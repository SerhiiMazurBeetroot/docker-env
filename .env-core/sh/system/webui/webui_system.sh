#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

webui_nginx_stop() {
	docker_nginx_container

	if [[ "${NGINX_EXISTS:-0}" -ne 1 ]]; then
		ECHO_ERROR "Nginx container not running"
		return 1
	fi

	# Do not compose down: that would also stop Web UI and Dozzle.
	docker stop nginx-proxy >/dev/null || return 1
	ECHO_SUCCESS "Nginx proxy stopped (Web UI left running)"
}

webui_dozzle_start() {
	docker_nginx_env
	docker_compose_runner "up -d dozzle" "$DIR_NGINX" || return 1
	ECHO_SUCCESS "Dozzle started"
}

webui_dozzle_stop() {
	if ! webui_service_running "nginx-dozzle"; then
		ECHO_ERROR "Dozzle is not running"
		return 1
	fi

	docker stop nginx-dozzle >/dev/null || return 1
	ECHO_SUCCESS "Dozzle stopped"
}

webui_dozzle_restart() {
	if ! webui_service_running "nginx-dozzle"; then
		ECHO_ERROR "Dozzle is not running"
		return 1
	fi

	docker restart nginx-dozzle >/dev/null || return 1
	ECHO_SUCCESS "Dozzle restarted"
}

webui_system_action() {
	local id="${1:-}"
	local action="${2:-}"

	webui_cli_boot

	case "$id" in
	nginx)
		case "$action" in
		start)
			docker_nginx_start
			;;
		stop)
			webui_nginx_stop
			;;
		restart)
			docker_nginx_container
			if [[ "${NGINX_EXISTS:-0}" -ne 1 ]]; then
				ECHO_ERROR "Nginx container not running"
				return 1
			fi
			docker_nginx_restart
			;;
		*)
			ECHO_ERROR "Unknown Nginx action: ${action}"
			return 1
			;;
		esac
		;;
	dozzle)
		case "$action" in
		start)
			webui_dozzle_start
			;;
		stop)
			webui_dozzle_stop
			;;
		restart)
			webui_dozzle_restart
			;;
		*)
			ECHO_ERROR "Unknown Dozzle action: ${action}"
			return 1
			;;
		esac
		;;
	*)
		ECHO_ERROR "Unknown system service: ${id}"
		return 1
		;;
	esac
}
