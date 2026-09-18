#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

create_nextjs() {
	unset_variables

	while true; do
		EMPTY_LINE
		ECHO_CYAN "======== Next.js Setup ======="
		ECHO_YELLOW "0 - Return to the previous menu"
		ECHO_GREEN "1 - Docker 🐳"
		ECHO_GREEN "2 - Local"

		actions=$(GET_USER_INPUT "select_one_of")

		case $actions in
		0)
			project_services_menu
			;;
		1)
			docker_create_nextjs
			unset_variables "PROJECT_TYPE"
			;;
		2)
			create_nextjs_app "$@"
			unset_variables "PROJECT_TYPE"
			;;
		esac
	done
}

create_nextjs_app() {
	unset_variables

	get_domain_name
	check_domain_exists

	if [[ $DOMAIN_EXISTS == 0 ]]; then
		get_project_dir "$@"
		set_custom_args
		check_data_before_continue_callback create_nextjs_app || return 1

		ECHO_INFO "Installing [$DOMAIN_FULL] v.$NEXTJS_VERSION locally..."

		#GET PORT
		get_all_ports
		export PORT_FRONT=$PORT

		get_project_dir "skip_question"

		# Create DIR
		mkdir -p "$PROJECT_ROOT_DIR"

		install_nextjs

		print_to_file_instances
	else
		ECHO_ERROR "Site already exists"
		return 1
	fi

}

install_nextjs() {
	cd "$PROJECT_ROOT_DIR" || {
		ECHO_ERROR "Cannot cd into $PROJECT_ROOT_DIR"
		return 1
	}

	MAJOR_VERSION=$(echo "$NEXTJS_VERSION" | cut -d'.' -f1)

	local npx_cmd=(npx "create-next-app@${NEXTJS_VERSION}" . --js --eslint --src-dir --import-alias="@/*")

	if [[ "$MAJOR_VERSION" -ge 15 ]]; then
		# > 15
		npx_cmd+=(--tailwind --app --turbopack)
	elif [[ "$MAJOR_VERSION" -eq 14 ]]; then
		# 14
		npx_cmd+=(--tailwind --app)
	else
		# 13 or older
		npx_cmd+=(--tailwind)
	fi

	# Run the assembled command
	"${npx_cmd[@]}"

	npm i

	cd - >/dev/null || return 1
}
