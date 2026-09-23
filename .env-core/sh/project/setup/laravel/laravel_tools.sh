#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

laravel_select_project() {
	if [[ -z "${DOMAIN_NAME:-}" ]]; then
		get_existing_domains "======= Laravel ======="
	fi

	if [[ ${PROJECT_TYPE:-} != "laravel" ]]; then
		ECHO_ERROR "Select a Laravel project"
		return 1
	fi

	if [[ ! -f "$PROJECT_ROOT_DIR/src/artisan" ]]; then
		ECHO_ERROR "Laravel app not found: $PROJECT_ROOT_DIR/src"
		return 1
	fi

	if ! docker ps --format '{{.Names}}' | grep -qx "$DOCKER_CONTAINER_APP"; then
		ECHO_ERROR "Container not running: $DOCKER_CONTAINER_APP"
		return 1
	fi
}

laravel_artisan() {
	laravel_select_project || return 1
	docker exec -u "$(id -u):$(id -g)" "$DOCKER_CONTAINER_APP" php artisan "$@"
}

laravel_artisan_prompt() {
	local command=""

	laravel_select_project || return 1
	read -rp "$(ECHO_ENTER "artisan command (example: route:list)")" command
	if [[ -z "$command" ]]; then
		ECHO_ERROR "No command entered"
		return 1
	fi

	# shellcheck disable=SC2086
	docker exec -u "$(id -u):$(id -g)" "$DOCKER_CONTAINER_APP" php artisan $command
}

laravel_migrate_fresh() {
	local yn

	laravel_select_project || return 1
	yn=$(GET_USER_INPUT "question" "This deletes every table in the Laravel database. Continue?" "n")
	if [[ ! "$yn" =~ ^[Yy]$ ]]; then
		ECHO_INFO "Cancelled"
		return 0
	fi

	laravel_artisan migrate:fresh --force
}

laravel_composer_require() {
	local package=""

	laravel_select_project || return 1
	read -rp "$(ECHO_ENTER "Composer package (example: laravel/sanctum)")" package
	if [[ -z "$package" ]]; then
		ECHO_ERROR "No package entered"
		return 1
	fi

	docker run --rm \
		-u "$(id -u):$(id -g)" \
		-e COMPOSER_HOME=/tmp/composer \
		-v "$PROJECT_ROOT_DIR/src":/app \
		-w /app \
		composer:2 \
		composer require "$package" --no-interaction
}
