#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

check_data_before_continue_callback() {
	local restart_fn="${1:-}"

	EMPTY_LINE
	ECHO_INFO "Check everything before proceeding:"

	while true; do
		notice_project_vars

		yn=$(GET_USER_INPUT "question" "Is that correct?" "y")

		case $yn in
		[Yy]*)
			return 0
			;;
		[Nn]*)
			ECHO_ERROR "Enter correct information"
			unset_variables

			# Same-shell restart (not ($1) — that is a subshell, so parent
			# create would continue and run the install steps twice).
			# Caller must `|| return` so this frame does not continue after restart.
			if [[ -n "$restart_fn" ]]; then
				"$restart_fn"
			fi
			return 1
			;;

		*) echo "Please answer [y/n]" ;;
		esac
	done
}

setup_installation_type_callback() {
	unset_variables

	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== $PROJECT_TYPE type ==="
		ECHO_YELLOW "[0] Return to main menu"
		ECHO_KEY_VALUE "[1]" "default"
		ECHO_KEY_VALUE "[2]" "custom"
		ECHO_KEY_VALUE "[3]" "beetroot"
		SETUP_TYPE=$(GET_USER_INPUT "select_one_of" "" "1")

		case $SETUP_TYPE in
		0)
			main_actions
			;;
		1)
			if ! _setup_require_new_domain; then
				continue
			fi
			get_project_dir "$@"
			set_project_args
			return 0
			;;
		2)
			if ! _setup_require_new_domain; then
				continue
			fi
			get_project_dir "$@"
			set_custom_args
			return 0
			;;
		3)
			if ! _setup_require_new_domain; then
				continue
			fi
			wp_beetroot_args "$@"
			return 0
			;;
		esac
	done
}

_setup_require_new_domain() {
	get_domain_name
	check_domain_exists

	if [[ $DOMAIN_EXISTS == 0 ]]; then
		return 0
	fi

	ECHO_ERROR "Site already exists"
	reset_session_var DOMAIN_NAME
	reset_session_var DOMAIN_FULL
	DOMAIN_EXISTS=0
	return 1
}
