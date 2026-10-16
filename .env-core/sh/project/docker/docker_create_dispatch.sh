#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# The one create gate for every project type. Everything that used to differ
# between the per-type wrappers now comes from the catalog in
# core/available_projects.sh: the setup flow, the CREATE_* flags and the after
# hook. Only the after hooks still live in docker_create_<type>.sh.
docker_create_dispatch() {
	local type="${1:-${PROJECT_TYPE:-}}"
	local canonical flow setup_args dir_question flags after
	local pair key value

	# Canonical id, so the old "projects" alias resolves to wordpress.
	canonical=$(project_field id "$type") || {
		ECHO_ERROR "Unsupported project type: ${type:-}"
		return 1
	}
	type="$canonical"

	flow=$(project_field flow "$type")
	setup_args=$(project_field setup_args "$type")
	dir_question=$(project_field dir_question "$type")
	flags=$(project_field flags "$type")
	after=$(project_field after "$type")

	if [[ -n "$after" ]] && ! declare -F "$after" >/dev/null 2>&1; then
		ECHO_ERROR "After hook missing: $after"
		return 1
	fi

	PROJECT_TYPE="$type"

	unset_variables
	project_require_nginx_for_type "$type" || return 1

	if [[ "$flow" == "installation_type" ]]; then
		# Asks default/custom/beetroot and resolves the dir and args itself.
		setup_installation_type_callback || return 1
		check_domain_exists
		docker_create_require_new_site || return 1
	else
		get_domain_name
		check_domain_exists
		docker_create_require_new_site || return 1
		get_project_dir "$dir_question" || return 1

		if [[ "$setup_args" == "1" ]]; then
			set_project_args || return 1
		fi
	fi

	# Restarts this same dispatch when the user rejects the summary.
	check_data_before_continue_callback docker_create_dispatch "$type" || return 1

	for pair in $flags; do
		key="${pair%%=*}"
		value="${pair#*=}"

		if ! is_safe_ident "$key"; then
			ECHO_ERROR "Invalid create flag for ${type}: $pair"
			return 1
		fi

		printf -v "$key" '%s' "$value"
	done

	docker_create_project "$after"
}
