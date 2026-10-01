#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# First directory that contains package.json for this site.
node_package_dir() {
	local candidate

	for candidate in \
		"${PROJECT_ROOT_DIR:-}" \
		"${PROJECT_FRONTEND_DIR:-}" \
		"${PROJECT_ROOT_DIR:-}/frontend" \
		"${PROJECT_ROOT_DIR:-}/app"; do
		[[ -n "$candidate" ]] || continue
		if [[ -f "$candidate/package.json" ]]; then
			printf '%s' "$candidate"
			return 0
		fi
	done

	return 1
}

site_container_logs() {
	local name="$1"

	if [[ -z "$name" ]]; then
		ECHO_ERROR "Container name is not set"
		return 1
	fi

	if ! container_is_running "$name"; then
		ECHO_ERROR "Container not running: $name"
		return 1
	fi

	ECHO_INFO "Last 80 lines from $name"
	docker logs --tail 80 "$name"
}

# Next.js create already installs on the host, into the mounted project.
nextjs_npm() {
	local dir

	if ! dir=$(node_package_dir); then
		ECHO_ERROR "package.json not found under ${PROJECT_ROOT_DIR:-the project}"
		return 1
	fi

	ECHO_YELLOW "npm $* in $dir"
	(cd "$dir" && npm "$@")
}

# nodejs_api hides host node_modules with an anonymous volume, so install inside the container.
node_npm_install() {
	local name dir workdir

	name="${DOCKER_CONTAINER_APP:-}"
	if [[ -z "$name" ]]; then
		ECHO_ERROR "App container is not set"
		return 1
	fi

	if container_is_running "$name"; then
		workdir=$(docker inspect -f '{{.Config.WorkingDir}}' "$name" 2>/dev/null || true)
		[[ -n "$workdir" ]] || workdir="/app"
		ECHO_YELLOW "npm install in $name ($workdir)"
		docker exec -i -w "$workdir" "$name" npm install
		return
	fi

	if ! dir=$(node_package_dir); then
		ECHO_ERROR "package.json not found, and $name is not running"
		return 1
	fi

	ECHO_YELLOW "Container is stopped. Running npm install on the host in $dir"
	(cd "$dir" && npm install)
}

node_health() {
	local url="https://${DOMAIN_FULL:-}/health"

	if [[ -z "${DOMAIN_FULL:-}" ]]; then
		ECHO_ERROR "Site URL is not set"
		return 1
	fi

	ECHO_INFO "$url"
	curl -kfsS "$url" || {
		ECHO_ERROR "Health check failed: $url"
		return 1
	}
	echo
}

directus_container_name() {
	printf '%s' "${DOMAIN_NAME:-}-directus"
}

directus_exec() {
	local name

	name=$(directus_container_name)
	if ! container_is_running "$name"; then
		ECHO_ERROR "Container not running: $name"
		return 1
	fi

	docker exec -i "$name" directus "$@"
}

php_composer_install() {
	local dir

	if [[ -f "${PROJECT_ROOT_DIR:-}/app/composer.json" ]]; then
		dir="$PROJECT_ROOT_DIR/app"
	elif [[ -f "${PROJECT_ROOT_DIR:-}/composer.json" ]]; then
		dir="$PROJECT_ROOT_DIR"
	else
		ECHO_ERROR "composer.json not found in ${PROJECT_ROOT_DIR:-the project}"
		return 1
	fi

	ECHO_YELLOW "composer install in $dir"
	docker run --rm \
		-u "$(id -u):$(id -g)" \
		-e COMPOSER_HOME=/tmp/composer \
		-v "$dir":/app \
		-w /app \
		composer:2 \
		composer install --no-interaction
}

elastic_cluster_health() {
	local url="https://${DOMAIN_FULL:-}/_cluster/health?pretty"

	if [[ -z "${DOMAIN_FULL:-}" ]]; then
		ECHO_ERROR "Site URL is not set"
		return 1
	fi

	ECHO_INFO "$url"
	curl -kfsS "$url" || {
		ECHO_ERROR "Cluster health failed: $url"
		return 1
	}
	echo
}
