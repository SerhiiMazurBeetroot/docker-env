#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_php() {
	unset_variables
	docker_create_require_nginx || return 1
	get_domain_name
	check_domain_exists
	docker_create_require_new_site || return 1
	get_project_dir "$@"
	set_project_args
	check_data_before_continue_callback docker_create_php || return 1

	docker_create_project
}
