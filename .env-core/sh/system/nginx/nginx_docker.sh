#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_nginx_setup() {
	if [ ! -d "$DIR_NGINX" ]; then
		ECHO_ERROR "Nginx folder does not exist"
		ECHO_ERROR "Make sure folder was not deleted"
	else
		if [ -f "$DIR_NGINX/docker-compose.yml" ]; then
			if [[ "${NGINX_EXISTS:-0}" -eq 1 ]]; then
				ECHO_ATTENTION "Nginx already setup and running"
			else
				ECHO_YELLOW "Container is not running"

				[ ! "$(docker volume ls | grep ssl-certs)" ] && docker volume create --name ssl-certs
				if [ ! "$(docker network ls | grep dockerwp)" ]; then
					docker network create dockerwp
					docker_nginx_start
				else
					docker_nginx_start
				fi

				#Fix certs DIR permissions
				if [[ $OSTYPE != "windows" ]]; then
					sudo chmod -R 777 "$DIR_NGINX"/certs-root/
				fi

				if [[ $OSTYPE == "linux" ]]; then
					docker_nghost_setup
				fi
				ECHO_SUCCESS "Container started"
			fi
		else
			ECHO_ERROR "Docker compose file for nginx-proxy not here"
			echo "Make sure file is not deleted"
			if [ "$(git status | grep nginx/docker-compose.yml)" ]; then
				ECHO_WARN_RED "File has been deleted"
				git checkout -- nginx/docker-compose.yml
				ECHO_SUCCESS "File has been restored"
				if [ ! "$(docker network ls | grep dockerwp)" ]; then
					docker network create dockerwp
					docker_nginx_start
				else
					docker_nginx_start
					if [[ "${NGINX_EXISTS:-0}" -eq 1 ]]; then
						ECHO_SUCCESS "Container started"
					else
						ECHO_ERROR "Problem starting container"
					fi
				fi
			else
				ECHO_ERROR "Recheck why docker-compose is not in folder"
			fi
		fi
	fi
}

docker_nginx_start() {
	if [[ "${NGINX_EXISTS:-0}" -eq 0 ]]; then
		docker_nginx_env
		# Bring the proxy up first so a Web UI image build cannot block Nginx.
		docker_compose_runner "up -d nginx mkcert dozzle" "$DIR_NGINX"
		docker_nginx_ensure_webui || true

		if [[ $OSTYPE == "linux" ]]; then
			docker_nghost_start
		fi
		ECHO_SUCCESS "Nginx started"
	else
		ECHO_ATTENTION "Nginx already setup and running"
		docker_nginx_ensure_webui || true
	fi
}

docker_nginx_stop() {
	if [[ "${NGINX_EXISTS:-0}" -eq 1 ]]; then
		docker_compose_runner "down" "$DIR_NGINX"

		if [[ $OSTYPE == "linux" ]]; then
			docker_nghost_stop
		fi
		ECHO_SUCCESS "Nginx container stopped"
	else
		ECHO_ERROR "Nginx container not running"
	fi
}

docker_nginx_restart() {
	if [[ ! -d "${DIR_NGINX:-}" ]]; then
		ECHO_WARN_YELLOW "Nginx compose directory not found: ${DIR_NGINX:-}"
		return 0
	fi

	if [[ "${NGINX_EXISTS:-0}" -eq 1 ]]; then
		docker_compose_runner "restart nginx" "$DIR_NGINX" || return 0

		if [[ $OSTYPE == "linux" ]]; then
			docker_nghost_restart
		fi

		ECHO_SUCCESS "Nginx restarted"

	else
		ECHO_ERROR "Nginx container not running"
	fi
}

docker_nginx_rebuild() {
	docker_nginx_env
	docker_compose_runner "up -d --force-recreate --no-deps --build nginx mkcert dozzle" "$DIR_NGINX"
	docker_nginx_ensure_webui || true

	if [[ $OSTYPE == "linux" ]]; then
		docker_nghost_rebuild
	fi
}

docker_nginx_container() {
	if docker ps --format '{{.Names}}' | grep -qE '(^)nginx-proxy($)'; then
		NGINX_EXISTS=1
	else
		NGINX_EXISTS=0
	fi
}

docker_nginx_resetup() {
	if [[ "${NGINX_EXISTS:-0}" -eq 1 ]]; then
		docker_nginx_stop

		[ "$(docker volume ls | grep ssl-certs)" ] && docker volume rm "ssl-certs" && ECHO_YELLOW "Deleting Volume ssl-certs" || echo "Volume ssl-certs not found"

		rm -rf "$DIR_NGINX/certs-root"

		docker_nginx_container
		docker_nginx_setup
	else
		ECHO_ERROR "Nginx container not running"
	fi
}

docker_nginx_env() {
	if [[ ! -f "$DIR_SYSTEM/.env" && -f "$DIR_SYSTEM/.env.example" ]]; then
		EMPTY_LINE
		ECHO_YELLOW "creating NGINX .env file..."
		cp -rf "$DIR_SYSTEM/.env.example" "$DIR_SYSTEM/.env"
	fi

	docker_nginx_set_env_key "${FILE_ENV:-$DIR_SYSTEM/.env}" "ENV_DIR" "${ENV_DIR:-}"
	docker_nginx_set_env_key "$DIR_NGINX/.env" "ENV_DIR" "${ENV_DIR:-}"
	docker_nginx_set_env_key "$DIR_NGINX/.env" "DOCKER_ENV_DIR" "${ENV_DIR:-}"
}

docker_nginx_set_env_key() {
	local file="${1:-}"
	local key="${2:-}"
	local value="${3:-}"

	[[ -n "$file" && -n "$key" ]] || return 0
	mkdir -p "$(dirname "$file")"
	touch "$file"

	if grep -qE "^${key}=" "$file"; then
		sed_inplace "s|^${key}=.*|${key}=${value}|" "$file"
	else
		printf '%s=%s\n' "$key" "$value" >>"$file"
	fi
}

docker_nginx_ensure_webui() {
	if [[ ! -f "${DIR_NGINX}/docker-compose.yml" ]]; then
		return 0
	fi

	if ! grep -qE '^[[:space:]]*webui:' "$DIR_NGINX/docker-compose.yml"; then
		return 0
	fi

	if [[ -z "${ENV_DIR:-}" ]]; then
		ECHO_WARN_YELLOW "ENV_DIR is not set; skipping Web UI"
		return 1
	fi

	if docker ps --format '{{.Names}}' 2>/dev/null | grep -qE "^${WEBUI_CONTAINER:-nginx-webui}$"; then
		ECHO_INFO "Web UI already running at http://${WEBUI_HOST:-127.0.0.1}:${WEBUI_PORT:-7777}"
		return 0
	fi

	ECHO_YELLOW "Starting Web UI with Nginx"
	docker_compose_runner "up -d webui" "$DIR_NGINX" || {
		ECHO_WARN_YELLOW "Web UI did not start (${WEBUI_CONTAINER:-nginx-webui})"
		return 1
	}

	sleep 0.4
	if docker ps --format '{{.Names}}' 2>/dev/null | grep -qE "^${WEBUI_CONTAINER:-nginx-webui}$"; then
		ECHO_SUCCESS "Web UI running at http://${WEBUI_HOST:-127.0.0.1}:${WEBUI_PORT:-7777}"
		return 0
	fi

	ECHO_WARN_YELLOW "Web UI container is not running"
	return 1
}
