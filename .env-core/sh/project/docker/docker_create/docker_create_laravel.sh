#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_laravel() {
	unset_variables
	docker_create_require_nginx || return 1
	get_domain_name
	check_domain_exists
	docker_create_require_new_site || return 1
	get_project_dir ""
	set_project_args
	check_data_before_continue_callback docker_create_laravel || return 1

	CREATE_TEMPLATE="copy"
	docker_create_project docker_create_laravel_after
}

docker_create_laravel_after() {
	install_laravel
	edit_file_gitignore
}

install_laravel() {
	if [ ! -f "$PROJECT_ROOT_DIR/artisan" ]; then
		ECHO_INFO "Creating Laravel app..."

		docker run --rm \
			-v "$PROJECT_ROOT_DIR/src":/app \
			-w /app \
			laravelsail/php82-composer:latest \
			composer create-project laravel/laravel .

		ECHO_SUCCESS "Laravel app created in $PROJECT_ROOT_DIR"
	else
		ECHO_INFO "Laravel app already exists, skipping creation"
	fi
}
