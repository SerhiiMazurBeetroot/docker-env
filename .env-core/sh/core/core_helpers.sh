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
	if [ ! -f "$FILE_INSTANCES" ]; then
		mkdir -p "$DIR_DATA"

		PORT=3309
		echo "$PORT | STATUS | DOMAIN_NAME | DOMAIN_FULL | DB_NAME | DB_TYPE | PROJECT_TYPE | PORT_FRONT | " >>"$FILE_INSTANCES"
	fi
}

print_to_file_instances() {
	if [[ $PORT && $DOMAIN_NAME ]]; then
		[[ $PORT_FRONT == "" ]] && PORT_FRONT=0

		instances_append "$PORT | active | $DOMAIN_NAME | $DOMAIN_FULL | $DB_NAME | $DB_TYPE | $PROJECT_TYPE | $PORT_FRONT |"
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
