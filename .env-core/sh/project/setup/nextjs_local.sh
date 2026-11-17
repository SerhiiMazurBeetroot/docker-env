#!/bin/bash

# Local Next.js is create-next-app on the host, so the template compose is
# missing. Nginx-proxy only publishes a host when a container on dockerwp sets
# VIRTUAL_HOST. This writes that compose into the project docker/ folder, the
# same place a Docker Next.js site uses, then starts it the same way.

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# True for a create-next-app site. Docker Next.js ships docker/Dockerfile.dev.
nextjs_is_local() {
	[[ ${PROJECT_TYPE:-} == "nextjs" ]] || return 1
	[[ -n "${PROJECT_ROOT_DIR:-}" ]] || return 1
	[[ -f "${PROJECT_ROOT_DIR}/docker/Dockerfile.dev" ]] && return 1
	[[ -f "${PROJECT_ROOT_DIR}/package.json" ]]
}

# Same directory the Docker template uses, so start/stop and Nginx see one compose.
nextjs_local_compose_dir() {
	printf '%s' "${PROJECT_ROOT_DIR}/docker"
}

_nextjs_local_saved_node() {
	local file="$1"
	local value=""

	[[ -f "$file" ]] || return 1

	value=$(awk -F= '/^NODE_VERSION=/{print $2; exit}' "$file")
	value=${value//\'/}
	value=${value//\"/}
	[[ -n "$value" ]] || return 1
	printf '%s' "$value"
}

_nextjs_local_port() {
	local port="${PORT_FRONT:-}"

	if [[ -z "$port" || "$port" == "0" ]]; then
		port="${PORT:-}"
	fi

	if [[ -z "$port" || "$port" == "0" ]] && [[ -n "${DOMAIN_NAME:-}" ]]; then
		port=$(instances_get port_front 2>/dev/null || true)
	fi
	if [[ -z "$port" || "$port" == "0" || "$port" == "null" ]] && [[ -n "${DOMAIN_NAME:-}" ]]; then
		port=$(instances_get port 2>/dev/null || true)
	fi

	[[ -n "$port" && "$port" != "null" && "$port" != "0" ]] || port="3000"
	printf '%s' "$port"
}

# Write docker/docker-compose.yml + docker/.env. Safe to call again.
nextjs_local_ensure() {
	local dir env_file node port

	nextjs_is_local || return 1
	[[ -n "${DOMAIN_NAME:-}" && -n "${DOMAIN_FULL:-}" ]] || return 1

	if ! is_safe_hostname "$DOMAIN_NAME" || ! is_safe_hostname "$DOMAIN_FULL"; then
		ECHO_ERROR "Refusing to write the local Next.js proxy: invalid host"
		return 1
	fi

	dir=$(nextjs_local_compose_dir)
	PROJECT_DOCKER_DIR="$dir"
	env_file="${dir}/.env"
	mkdir -p "$dir"

	node="${NODE_VERSION:-}"
	if [[ -z "$node" ]]; then
		node=$(_nextjs_local_saved_node "$env_file" || true)
	fi
	[[ -n "$node" ]] || node="22"

	port=$(_nextjs_local_port)
	PORT_FRONT="$port"

	cat >"$env_file" <<EOF
COMPOSE_PROJECT_NAME='${COMPOSE_PROJECT_NAME:-}'
VIRTUAL_HOST='${DOMAIN_FULL}'
PORT_FRONT=${port}
NODE_VERSION=${node}
EOF

	# Same contract as the Docker Next.js template: VIRTUAL_HOST on dockerwp.
	# Nginx-proxy reads that env and publishes the host. No separate sidecar.
	cat >"${dir}/docker-compose.yml" <<EOF
services:
  ${DOMAIN_NAME}-nextjs:
    image: node:${node}-bookworm-slim
    container_name: ${DOMAIN_NAME}-nextjs
    working_dir: /app
    init: true
    command: sh -c "if [ ! -x node_modules/.bin/next ]; then npm install; fi && exec npm run dev -- -H 0.0.0.0 -p 3000"
    env_file: .env
    environment:
      VIRTUAL_HOST: \${VIRTUAL_HOST}
      VIRTUAL_PORT: "3000"
      WATCHPACK_POLLING: "true"
      HOSTNAME: 0.0.0.0
    volumes:
      - ../:/app
      - /app/node_modules
      - /app/.next
    ports:
      - "\${PORT_FRONT}:3000"
    expose:
      - "3000"
    restart: unless-stopped

networks:
  default:
    name: dockerwp
    external: true
EOF
}

# Register the host with Nginx the same way a Docker Next.js container does,
# and make sure /etc/hosts has the name.
nextjs_local_start() {
	set_project_vars || return 1
	nextjs_local_ensure || return 1

	if ! setup_hosts_file add; then
		ECHO_WARN_RED "Could not update the hosts file. Project setup will continue."
	fi

	if container_is_running; then
		ECHO_WARN_RED "Containers already running for this domain"
		return 0
	fi

	docker_nginx_container || true
	if [[ ${NGINX_EXISTS:-0} -ne 1 ]]; then
		ECHO_ERROR "Nginx container not running"
		return 1
	fi

	ECHO_YELLOW "Starting local Next.js on https://${DOMAIN_FULL}"
	docker_compose_runner "up -d" || return 1

	# mkcert writes the cert a few seconds after VIRTUAL_HOST appears.
	# Reloading Nginx before that leaves the vhost rejecting TLS.
	local i
	for ((i = 0; i < 20; i++)); do
		if docker exec nginx-proxy test -e "/etc/nginx/certs/${DOMAIN_FULL}.crt" 2>/dev/null; then
			break
		fi
		sleep 1
	done
	docker_nginx_restart || true
	ECHO_SUCCESS "Local Next.js is up [${DOMAIN_FULL}]"
}

nextjs_local_remove() {
	local dir legacy

	nextjs_is_local || return 0
	[[ -n "${DOMAIN_NAME:-}" ]] || return 0

	dir=$(nextjs_local_compose_dir)
	if [[ -f "${dir}/docker-compose.yml" ]]; then
		docker_compose_runner "down -v" "$dir" || true
		rm -f "${dir}/docker-compose.yml" "${dir}/.env"
		rmdir "$dir" 2>/dev/null || true
	fi

	# Older builds kept a sidecar under data/. Drop it if one is still around.
	legacy="${DIR_DATA}/local-nextjs/${DOMAIN_NAME}"
	if [[ -f "${legacy}/docker-compose.yml" ]]; then
		docker_compose_runner "down -v" "$legacy" || true
		rm -rf "$legacy"
	fi
}
