#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

running_projects_list() {
	local ACTION="${1:-}"
	local -a running_container=()
	local -a existing_container=()
	local DOMAIN_EXISTS DOMAIN_NAME choice

	# unset_variables

	# Find running containers matching available projects
	for PROJECT in "${ALL_PROJECT_TYPES[@]}"; do
		while IFS= read -r container; do
			running_container+=("$container")
		done < <(docker ps --format '{{.Names}}' | grep -E ".*-${PROJECT}\$" | sed -E "s/-${PROJECT}\$//")
	done

	# Verify containers exist in this environment
	for container in "${running_container[@]+"${running_container[@]}"}"; do
		# macOS awk compatibility - use POSIX syntax
		DOMAIN_EXISTS=$(instances_domain_for_container "$container")
		[[ -n "$DOMAIN_EXISTS" ]] && existing_container+=("$DOMAIN_EXISTS")
	done

	running_container=("${existing_container[@]+"${existing_container[@]}"}")

	if ((${#running_container[@]} == 0)); then
		ECHO_ERROR "Sites not running"
		project_services_menu
		return
	fi

	# Interactive selection loop
	while true; do
		EMPTY_LINE
		ECHO_CYAN "$ACTION"
		ECHO_YELLOW "[0] Return to the previous menu"

		print_list "${running_container[@]}"

		choice=$(GET_USER_INPUT "select_one_of")
		choice="${choice:-0}"

		if ((choice > 0 && choice <= ${#running_container[@]})); then
			DOMAIN_NAME="${running_container[$((choice - 1))]}"
			get_project_dir "skip_question"
			break
		elif ((choice == 0)); then
			project_services_menu
			return
		else
			ECHO_WARN_RED "Wrong option"
		fi
	done
}
