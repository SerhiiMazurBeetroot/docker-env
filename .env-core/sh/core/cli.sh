#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

cli_usage() {
	local i

	if [[ -f "${FILE_SETTINGS:-}" ]]; then
		env_mode
	fi

	echo "Usage:"
	echo "  docker-env"
	echo "  docker-env create --type wordpress --name blog"
	echo "  docker-env create --type wordpress --name blog --domain dev.blog.local"
	echo
	echo "Types:"

	build_visible_projects
	for ((i = 0; i < ${#AVAILABLE_PROJECTS[@]}; i++)); do
		echo "  ${AVAILABLE_PROJECTS[$i]}"
	done
}

cli_create() {
	local type="" name="" domain=""

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--type)
			[[ $# -ge 2 ]] || {
				ECHO_ERROR "--type needs a value"
				return 1
			}
			type="$2"
			shift 2
			;;
		--name)
			[[ $# -ge 2 ]] || {
				ECHO_ERROR "--name needs a value"
				return 1
			}
			name="$2"
			shift 2
			;;
		--domain)
			[[ $# -ge 2 ]] || {
				ECHO_ERROR "--domain needs a value"
				return 1
			}
			domain="$2"
			shift 2
			;;
		-h | --help)
			cli_usage
			return 0
			;;
		*)
			ECHO_ERROR "Unknown option: $1"
			cli_usage
			return 1
			;;
		esac
	done

	if [[ -z "$type" || -z "$name" ]]; then
		ECHO_ERROR "create needs --type and --name"
		cli_usage
		return 1
	fi

	healthcheck

	build_visible_projects
	local allowed=0 id
	for id in "${AVAILABLE_PROJECTS[@]}"; do
		if [[ "$id" == "$type" ]]; then
			allowed=1
			break
		fi
	done

	if [[ "$allowed" -ne 1 ]]; then
		ECHO_ERROR "Unsupported project type: $type"
		cli_usage
		return 1
	fi

	if [[ -n "$domain" ]] && ! is_safe_hostname "$domain"; then
		ECHO_ERROR "Invalid domain. Use letters, numbers, dots, and hyphens only."
		return 1
	fi

	export CLI_NONINTERACTIVE=1
	export CLI_NAME="$name"
	export CLI_DOMAIN="$domain"
	PROJECT_TYPE="$type"
	SETUP_ACTION="create"
	SETUP_TYPE=1

	create_project_by_type "$type"
}

cli_dispatch() {
	local cmd="${1:-}"

	if [[ $# -gt 0 ]]; then
		shift
	fi

	case "$cmd" in
	create)
		cli_create "$@"
		;;
	help | -h | --help)
		cli_usage
		;;
	*)
		ECHO_ERROR "Unknown command: $cmd"
		cli_usage
		return 1
		;;
	esac
}
