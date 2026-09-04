#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

get_existing_domains() {
	ACTION=${1:-}

	if [ -z "${DOMAIN_NAME:-}" ]; then
		EMPTY_LINE
		ECHO_CYAN "======== Project Status ======="
		ECHO_YELLOW "[0] Return to the services menu"
		ECHO_KEY_VALUE "[1]" "active [default]"
		ECHO_KEY_VALUE "[2]" "inactive"
		ECHO_KEY_VALUE "[3]" "all"

		first_choice=$(GET_USER_INPUT "select_one_of")

		if [[ "$first_choice" == "0" ]]; then
			project_services_menu
		fi

		status_filter="active"
		case "$first_choice" in
		1) status_filter="active" ;;
		2) status_filter="inactive" ;;
		3) status_filter="all" ;;
		esac

		local string
		string=$(instances_domains "$status_filter")

		if [ "$string" ]; then
			OptionList=($string)

			while true; do
				EMPTY_LINE
				ECHO_CYAN "$ACTION"
				ECHO_YELLOW "[0] Return to the previous menu"

				print_list "${OptionList[@]}"

				choice=$(GET_USER_INPUT "select_one_of")

				[ -z "$choice" ] && choice=-1
				if (("$choice" > 0 && "$choice" <= ${#OptionList[@]})); then
					userChoice="${OptionList[$(($choice - 1))]}"
					DOMAIN_NAME="$(echo "${userChoice}" | sed -E 's/(active|inactive)\|//g')"

					get_project_dir "skip_question"
					break
				else
					if [ "$choice" == 0 ]; then
						docker_menu
					else
						ECHO_WARN_RED "Wrong option"
					fi
				fi
			done
		else
			ECHO_ERROR "Sites don't exists"
			main_actions
		fi
	fi
}
