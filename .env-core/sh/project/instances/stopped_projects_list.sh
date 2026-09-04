#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

stopped_projects_list() {
	local ACTION="${1:-}"
	local -a running_container=()
	local -a existing_container=()
	local -a stopped_container=()
	local existing_string DOMAIN_NAME choice

	# Find running containers matching available projects
	for PROJECT in "${ALL_PROJECT_TYPES[@]}"; do
		while IFS= read -r container; do
			running_container+=("$container")
		done < <(docker ps --format '{{.Names}}' | grep -E ".*-${PROJECT}\$" | sed -E "s/-${PROJECT}\$//")
	done

	# Get active projects from instances file
	existing_string=$(instances_domains "active")

	# Filter for active projects only
	while IFS= read -r line; do
		if [[ "$line" =~ active\|([A-Za-z0-9.-]+) ]]; then
			existing_container+=("${BASH_REMATCH[1]}")
		fi
	done < <(echo "$existing_string" | grep -o 'active|[A-Za-z0-9.-]*' || true)

	# Check if we have any containers to work with
	if ((${#existing_container[@]} == 0)); then
		ECHO_ERROR "No active sites found"
		project_services_menu
		return
	fi

	# Find stopped containers (in existing but not running)
	for container in "${existing_container[@]}"; do
		local is_running=false
		for running in "${running_container[@]+"${running_container[@]}"}"; do
			if [[ "$container" == "$running" ]]; then
				is_running=true
				break
			fi
		done
		[[ "$is_running" == false ]] && stopped_container+=("$container")
	done

	# Check if we have stopped containers
	if ((${#stopped_container[@]} == 0)); then
		ECHO_ERROR "No stopped sites found"
		project_services_menu
		return
	fi

	# Interactive selection loop
	while true; do
		EMPTY_LINE
		ECHO_CYAN "$ACTION"
		ECHO_YELLOW "[0] Return to the previous menu"

		print_list "${stopped_container[@]}"

		choice=$(GET_USER_INPUT "select_one_of")
		choice="${choice:-0}"

		if ((choice > 0 && choice <= ${#stopped_container[@]})); then
			DOMAIN_NAME="${stopped_container[$((choice - 1))]}"
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
