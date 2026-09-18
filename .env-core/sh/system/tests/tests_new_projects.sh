#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

tests_create_all_projects() {
	local failed=()
	local type

	load_project_modules
	tests_build_project_types

	EMPTY_LINE
	ECHO_WARN_YELLOW "Start testing: Create all projects (${#TESTS_PROJECT_TYPES[@]} types)"

	for type in "${TESTS_PROJECT_TYPES[@]}"; do
		EMPTY_LINE
		ECHO_CYAN "---- $type ----"

		if tests_create_one_project "$type"; then
			ECHO_SUCCESS "Create + health: $type"
		else
			failed+=("$type")
		fi

		tests_reset_project_globals
	done

	tests_print_summary "Create all projects" "${failed[@]}"
}

tests_delete_all_projects() {
	local type

	load_project_modules
	tests_build_project_types

	EMPTY_LINE
	ECHO_WARN_YELLOW "Start testing: Delete all projects (${#TESTS_PROJECT_TYPES[@]} types)"

	for type in "${TESTS_PROJECT_TYPES[@]}"; do
		tests_prepare_project "$type"
		tests_teardown_project
		tests_reset_project_globals
	done

	ECHO_SUCCESS "Testing: Delete all projects"
}
