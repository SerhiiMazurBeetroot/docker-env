#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

webui_server_pid() {
	if [[ -f "${FILE_WEBUI_PID:-}" ]]; then
		tr -d '[:space:]' <"$FILE_WEBUI_PID"
	fi
}

webui_stop_host_process() {
	local pid comm
	pid=$(webui_server_pid)

	if [[ -z "$pid" ]]; then
		[[ -n "${FILE_WEBUI_PID:-}" && -f "$FILE_WEBUI_PID" ]] && rm -f "$FILE_WEBUI_PID"
		return 0
	fi

	# Stale pid files can reuse the current CLI pid and would kill the menu.
	if [[ "$pid" == "$$" || "$pid" == "${PPID:-}" ]]; then
		rm -f "$FILE_WEBUI_PID"
		return 0
	fi

	if kill -0 "$pid" 2>/dev/null; then
		comm=$(ps -p "$pid" -o comm= 2>/dev/null | tr -d ' ')
		if [[ "$comm" != "node" && "$comm" != "nodejs" ]]; then
			rm -f "$FILE_WEBUI_PID"
			return 0
		fi
		kill "$pid" 2>/dev/null || true
		sleep 0.2
		kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
	fi
	[[ -n "${FILE_WEBUI_PID:-}" && -f "$FILE_WEBUI_PID" ]] && rm -f "$FILE_WEBUI_PID"
}

webui_server_is_running() {
	docker ps --format '{{.Names}}' 2>/dev/null | grep -qE "^${WEBUI_CONTAINER:-nginx-webui}$"
}

webui_is_dev() {
	docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "${WEBUI_CONTAINER:-nginx-webui}" 2>/dev/null \
		| grep -qx 'WEBUI_DEV=1'
}

webui_status_label() {
	if webui_server_is_running; then
		if webui_is_dev; then
			printf 'running %s (dev)' "$(webui_url)"
		else
			printf 'running %s' "$(webui_url)"
		fi
	else
		printf 'stopped'
	fi
}

webui_compose_webui() {
	local files="${1:-}"
	local args="${2:-}"

	if [[ -z "${DIR_NGINX:-}" || ! -f "${DIR_NGINX}/docker-compose.yml" ]]; then
		ECHO_ERROR "Nginx compose directory not found: ${DIR_NGINX:-}"
		return 1
	fi

	if [[ -z "${ENV_DIR:-}" ]]; then
		ECHO_ERROR "ENV_DIR is not set"
		return 1
	fi

	# shellcheck disable=SC2086
	(
		docker_compose_unset_interpolation_env
		$DOCKER_COMPOSE_CMD --project-directory "$DIR_NGINX" $files $args
	)
}

webui_open_browser() {
	local url
	url=$(webui_url)

	if [[ "${OSTYPE:-}" == "darwin" ]]; then
		open "$url" >/dev/null 2>&1 || true
	elif command -v xdg-open >/dev/null 2>&1; then
		xdg-open "$url" >/dev/null 2>&1 || true
	fi
}

webui_server_start() {
	if webui_server_is_running; then
		webui_stop_host_process
		ECHO_ATTENTION "Web UI already running at $(webui_url)"
		return 0
	fi

	webui_stop_host_process

	docker_nginx_container
	docker_nginx_env

	if [[ ! -d "${DIR_NGINX:-}" || ! -f "${DIR_NGINX}/docker-compose.yml" ]]; then
		ECHO_ERROR "Nginx compose directory not found: ${DIR_NGINX:-}"
		return 1
	fi

	if [[ -z "${ENV_DIR:-}" ]]; then
		ECHO_ERROR "ENV_DIR is not set"
		return 1
	fi

	if [[ "${NGINX_EXISTS:-0}" -eq 0 ]]; then
		ECHO_YELLOW "Starting Nginx stack (Web UI starts with it)"
		docker_nginx_start || return 1
	else
		docker_nginx_ensure_webui || return 1
	fi

	sleep 0.6

	if ! webui_server_is_running; then
		ECHO_ERROR "Web UI container failed to start (${WEBUI_CONTAINER:-nginx-webui})"
		return 1
	fi

	ECHO_SUCCESS "Web UI started at $(webui_url)"
}

webui_server_stop() {
	webui_stop_host_process

	if ! webui_server_is_running; then
		ECHO_ERROR "Web UI is not running"
		return 1
	fi

	docker stop "${WEBUI_CONTAINER:-nginx-webui}" >/dev/null || return 1
	ECHO_SUCCESS "Web UI stopped"
}

webui_server_rebuild() {
	webui_stop_host_process
	docker_nginx_container
	docker_nginx_env

	if [[ ! -d "${DIR_NGINX:-}" || ! -f "${DIR_NGINX}/docker-compose.yml" ]]; then
		ECHO_ERROR "Nginx compose directory not found: ${DIR_NGINX:-}"
		return 1
	fi

	if [[ -z "${ENV_DIR:-}" ]]; then
		ECHO_ERROR "ENV_DIR is not set"
		return 1
	fi

	ECHO_YELLOW "Rebuilding Web UI image (production)"
	webui_compose_webui \
		"-f ${DIR_NGINX}/docker-compose.yml" \
		"up -d --build --force-recreate --no-deps webui" || return 1

	sleep 0.6

	if ! webui_server_is_running; then
		ECHO_ERROR "Web UI container failed to start (${WEBUI_CONTAINER:-nginx-webui})"
		return 1
	fi

	ECHO_SUCCESS "Web UI rebuilt at $(webui_url)"
}

webui_server_develop() {
	webui_stop_host_process
	docker_nginx_container
	docker_nginx_env

	if [[ ! -f "${DIR_NGINX}/docker-compose.webui-dev.yml" ]]; then
		ECHO_ERROR "Develop compose file not found: ${DIR_NGINX}/docker-compose.webui-dev.yml"
		return 1
	fi

	ECHO_YELLOW "Starting Web UI develop image (next dev, source mounted)"
	webui_compose_webui \
		"-f ${DIR_NGINX}/docker-compose.yml -f ${DIR_NGINX}/docker-compose.webui-dev.yml" \
		"up -d --build --force-recreate --no-deps webui" || return 1

	sleep 1.2

	if ! webui_server_is_running; then
		ECHO_ERROR "Web UI develop container failed to start (${WEBUI_CONTAINER:-nginx-webui})"
		return 1
	fi

	ECHO_SUCCESS "Web UI develop at $(webui_url) — edit .env-core/webui, no rebuild"
}
