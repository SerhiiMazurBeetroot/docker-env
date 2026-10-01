#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

project_services_menu() {
	load_project_modules

	local -a names=()
	local -a types=()
	local -a hosts=()
	local -a states=()
	local line name host type state
	local index choice

	while true; do
		names=()
		types=()
		hosts=()
		states=()

		while IFS=$'\t' read -r name type host state; do
			[[ -z "$name" ]] && continue
			names+=("$name")
			types+=("$type")
			hosts+=("$host")
			states+=("$state")
		done < <(instances_visible_sites)

		EMPTY_LINE
		ECHO_CYAN "==== Sites ===="
		ECHO_YELLOW "[0] Return to main menu"

		if ((${#names[@]} == 0)); then
			ECHO_YELLOW "No sites yet. Create one from New project."
		else
			for ((index = 0; index < ${#names[@]}; index++)); do
				printf '%b[%d]%b %-16s %-20s %-10s https://%s\n' \
					"$GREEN" "$((index + 1))" "$NC" \
					"${names[$index]}" \
					"$(site_type_label "${types[$index]}")" \
					"${states[$index]}" \
					"${hosts[$index]}"
			done
		fi

		choice=$(GET_USER_INPUT "select_one_of")
		choice="${choice:-0}"

		if [[ "$choice" == "0" ]]; then
			return 0
		fi

		if ((choice < 1 || choice > ${#names[@]})); then
			ECHO_WARN_RED "Wrong option"
			continue
		fi

		reset_session_var PROJECT_TYPE
		DOMAIN_NAME="${names[$((choice - 1))]}"
		get_project_dir "skip_question" || continue
		site_menu
	done
}
