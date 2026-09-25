#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

fix_linux_watchers() {
	if [[ $OSTYPE == "linux" ]]; then
		limit=$(cat /proc/sys/fs/inotify/max_user_watches)
		if [[ "$limit" -lt 524288 ]]; then
			EMPTY_LINE
			ECHO_YELLOW "Change system limit for number of file watchers"
			echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
		fi
	fi
}

check_instances_file_exists() {
	mkdir -p "$DIR_DATA"

	# Runs on every start, including offline. env_migration repeats this
	# once CORE_VERSION is still below 3.0.0; the function is idempotent.
	if declare -F migrate_instances_log_to_json >/dev/null 2>&1; then
		migrate_instances_log_to_json
		return 0
	fi

	if [[ ! -f "$FILE_INSTANCES" ]]; then
		printf '%s\n' '{"sites":[]}' >"$FILE_INSTANCES"
	fi
}

print_to_file_instances() {
	local status="${1:-active}"
	load_project_modules

	if [[ $PORT && $DOMAIN_NAME ]]; then
		[[ $PORT_FRONT == "" ]] && PORT_FRONT=0

		instances_append "$status"
	fi
}

# usage array:
# Call: print_list "${ARRAY[@]}"

print_list() {
	OPTION_LIST=("$@")

	for ((i = 0; i < ${#OPTION_LIST[@]}; i++)); do
		index=$((i + 1))
		option="${OPTION_LIST[i]}"
		ECHO_KEY_VALUE "[$index]" "$option"
	done
}

sed_inplace() {
	local expr="$1"
	local file="${2:-}"

	if [[ -z "$file" ]]; then
		case "$(uname)" in
		Darwin)
			sed -i '' "$@"
			;;
		*)
			sed -i "$@"
			;;
		esac
		return
	fi

	case "$(uname)" in
	Darwin)
		sed -i '' "$expr" "$file"
		;;
	*)
		sed -i "$expr" "$file"
		;;
	esac
}

update_core_env_file() {
	local HOSTS_FILE="/etc/hosts"

	if [[ $OSTYPE == "windows" ]]; then
		HOSTS_FILE="C:/Windows/System32/drivers/etc/hosts"
	fi

	# Update the .env file
	sed_inplace "s|^HOSTS_FILE=.*$|HOSTS_FILE=${HOSTS_FILE}|g" "$FILE_ENV"
}

get_bash_version() {
	# Check if Bash version is 4 or higher
	if [[ "${BASH_VERSINFO:-0}" -lt 4 ]]; then
		ECHO_ERROR "Please install Bash 4 or higher."
		ECHO_KEY_VALUE "- bash: " "$BASH_VERSION"

		exit 1
	fi
}
