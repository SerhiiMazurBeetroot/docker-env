#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

replace_variables() {
	local compose_files=(
		"${PROJECT_DOCKER_DIR:-}/docker-compose.yml"
		"${PROJECT_DOCKER_DIR:-}/docker-compose.override.yml"
		"${PROJECT_DOCKER_DIR:-}/servers.json"
		"${PROJECT_ROOT_DIR:-}/docker-compose.yml"
	)
	local file

	for file in "${compose_files[@]}"; do
		if [[ -n "$file" && -f "$file" ]]; then
			sed_inplace "s|{DOMAIN_NAME}|${DOMAIN_NAME}|g" "$file"
		fi
	done
}

# Copy bundled Dockerfiles over a cloned site. Used only in development
# (ENV_MODE=development) so GitHub templates stay the source for real creates.
docker_overlay_bundled_dockerfiles() {
	local src="${ENV_DIR}/.env-core/templates/${PROJECT_TYPE}/docker"
	local dest="${PROJECT_DOCKER_DIR:-$PROJECT_ROOT_DIR/docker}"
	local file

	[[ -d "$src" && -d "$dest" ]] || return 0

	for file in "$src"/Dockerfile "$src"/Dockerfile.*; do
		[[ -f "$file" ]] || continue
		cp "$file" "$dest/"
	done
}

# Compose interpolates ${VAR} from the shell before the project .env file.
# const.sh exports many keys as empty strings — those override project .env and
# break MariaDB passwords, Directus build args (directus/directus:), etc.
# Session vars (DOMAIN_NAME, paths, …) must NOT be unset here — rebuild/restart
# runs compose then docker_restart in the same shell.
docker_compose_unset_interpolation_env() {
	unset \
		COMPOSE_PROJECT_NAME PORT PORT_FRONT \
		WP_VERSION TABLE_PREFIX WP_USER WP_PASSWORD PHP_VERSION \
		MONGODB_LOCAL_PORT MONGO_EXPRESS_PORT NODE_VERSION NEXTJS_VERSION \
		DIRECTUS_VERSION ELASTIC_VERSION ELASTIC_PORT KIBANA_PORT LOGSTASH_PORT \
		MYSQL_ROOT_PASSWORD MYSQL_DATABASE MARIADB_ROOT_PASSWORD MARIADB_DATABASE \
		DB_NAME \
		2>/dev/null || true
}

docker_compose_runner() {
	local COMMAND=${1:-}
	local DIR_DOCKER=${2:-}

	if [[ -z "$DIR_DOCKER" ]]; then
		DIR_DOCKER="${PROJECT_DOCKER_DIR:-}"
	fi

	if [[ -z "$DIR_DOCKER" || ! -d "$DIR_DOCKER" ]]; then
		ECHO_ERROR "Docker compose directory not found: ${DIR_DOCKER:-}"
		return 1
	fi

	# Subshell: unset empty session exports so Compose reads the project .env.
	# Parent keeps DOMAIN_NAME / paths for later docker_restart in the same shell.
	# shellcheck disable=SC2086
	(
		docker_compose_unset_interpolation_env
		$DOCKER_COMPOSE_CMD --project-directory "$DIR_DOCKER" $COMMAND
	)
}

# Backwards-compatible alias for tests_helpers.
docker_compose_unset_project_env() {
	docker_compose_unset_interpolation_env
}

# Run compose in a subshell (safe interpolation) and capture stdout — for tests/ps checks.
docker_compose_output() {
	local COMMAND=${1:-}
	local DIR_DOCKER=${2:-${PROJECT_DOCKER_DIR:-}}

	[[ -n "$DIR_DOCKER" && -d "$DIR_DOCKER" ]] || return 1

	# shellcheck disable=SC2086
	(
		docker_compose_unset_interpolation_env
		$DOCKER_COMPOSE_CMD --project-directory "$DIR_DOCKER" $COMMAND
	)
}

docker_official_image_exists() {
	ECHO_YELLOW "Cheking docker image exists: $1"

	# First check local image
	exist=$(docker image inspect "$1" >/dev/null 2>&1 && echo yes || echo no)

	# Second check FILE_DOCKER_HUB
	if [[ -f "$FILE_DOCKER_HUB" ]]; then
		remote_image_exist=$(awk '/'"$1"'/{print $1}' "$FILE_DOCKER_HUB")
		[[ ! "$remote_image_exist" ]] && exist=no || exist=yes
	fi

	# Only after than check remote (increase limit)
	if [[ "$exist" == "no" ]]; then
		exist=$(docker manifest inspect "$1" >/dev/null 2>&1 && echo yes || echo no)
	fi

	if [[ "$exist" == "no" ]]; then
		WP_VERSION=$WP_PREV_VER
	else
		WP_VERSION=$WP_LATEST_VER

		# Save image to FILE_DOCKER_HUB
		if [ ! "$remote_image_exist" ]; then
			echo "$1" >>"$FILE_DOCKER_HUB"
		fi
	fi
}

get_docker_ip() {
	local container=${1:-}
	if [ -n "$container" ]; then
		export DOCKER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $container)
	fi
}
