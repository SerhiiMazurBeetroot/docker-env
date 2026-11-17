#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

env_settings() {
	check_env_version "$@"

	while true; do
		EMPTY_LINE
		ECHO_CYAN "===== Settings ===="
		ECHO_YELLOW "[0] Return to main menu"
		ECHO_KEY_VALUE "[1] ENV_UPDATES:" "$ENV_UPDATES"
		ECHO_KEY_VALUE "[2] ENV_THEME:" "$ENV_THEME"
		ECHO_KEY_VALUE "[3] Versions"

		settings=$(GET_USER_INPUT "select_one_of")

		case $settings in
		0)
			return 0
			;;
		1)
			update_env
			;;
		2)
			change_env_theme
			;;
		3)
			versions
			;;
		esac
	done
}

change_env_theme() {
	ENV_THEME=$(settings_get ENV_THEME)
	ENV_VERSION=$(settings_get ENV_VERSION)

	if [ "$ENV_THEME" = 'dark' ]; then
		settings=("ENV_THEME=light")
	else
		settings=("ENV_THEME=dark")
	fi

	save_settings "${settings[@]}"

	# Colors are plain variables set when colors.sh is sourced. Source it again so the
	# menu switches theme now, instead of ending the session.
	# shellcheck disable=SC1091
	source "${ENV_DIR}/.env-core/sh/core/utils/colors.sh"
	ECHO_SUCCESS "Theme changed to ${settings[0]#ENV_THEME=}"
}

check_env_version() {
	local action=${1:-}

	load_project_modules
	env_migration
	add_alias

	ENV_THEME=$(settings_get ENV_THEME)
	ENV_VERSION=$(settings_get ENV_VERSION)
	ENV_DATE_CHECK=$(settings_get ENV_DATE_CHECK)
	DATE_NOW=$(date +'%m/%d/%Y')

	if [[ $ENV_DATE_CHECK == '' ]]; then
		check_git_version

		#First setup
		echo "ENV_DATE_CHECK=$DATE_NOW" >>"$FILE_SETTINGS"
	else
		#Run only once a day
		if [[ "$ENV_DATE_CHECK" != "$DATE_NOW" || "$action" != "daily" ]]; then
			check_git_version

			#Replace ENV_DATE_CHECK
			sed_inplace '/ENV_DATE_CHECK/d' "$FILE_SETTINGS"
			echo "ENV_DATE_CHECK=$DATE_NOW" >>"$FILE_SETTINGS"
		fi
	fi
}

# usage array:
# Declare: settings=("ENV_THEME=light" "SOME_OTHER_SETTING=value")
# Call:    save_settings "${settings[@]}"

# usage single:
# Call:    save_settings "ENV_THEME=dark"

save_settings() {
	local settings=("$@")

	# Read existing settings from file into separate arrays
	local existing_keys=()
	local existing_values=()

	if [[ -f "$FILE_SETTINGS" ]]; then
		while IFS='=' read -r existing_key existing_value; do
			existing_keys+=("$existing_key")
			existing_values+=("$existing_value")
		done <"$FILE_SETTINGS"
	fi

	# Update existing settings and add new settings to the separate arrays
	for setting in "${settings[@]}"; do
		key="${setting%=*}"
		value="${setting#*=}"

		# Check if the key already exists in the array
		index=""
		for ((i = 0; i < ${#existing_keys[@]}; i++)); do
			if [[ "${existing_keys[i]}" == "$key" ]]; then
				index=$i
				break
			fi
		done

		if [[ -n $index ]]; then
			existing_values[index]="$value"
		else
			existing_keys+=("$key")
			existing_values+=("$value")
		fi
	done

	# Save the updated settings to the file
	for ((i = 0; i < ${#existing_keys[@]}; i++)); do
		echo "${existing_keys[i]}=${existing_values[i]}"
	done >"$FILE_SETTINGS"
	protect_settings_file
}

core_version() {
	local saved_ver

	[[ -f "$FILE_SETTINGS" ]] || return 0

	saved_ver=$(awk -F= '/^CORE_VERSION=/{print $2; exit}' "$FILE_SETTINGS" | tr -d '[:space:]')
	if [[ -z "$saved_ver" || "$saved_ver" != "$CORE_VERSION" ]]; then
		save_settings "CORE_VERSION=$CORE_VERSION"
	fi
}

# True when today's update check has not been recorded yet.
env_updates_due() {
	local saved today

	[[ -f "${FILE_SETTINGS:-}" ]] || return 0

	saved=$(awk -F= '/^ENV_DATE_CHECK=/{print $2; exit}' "$FILE_SETTINGS")
	today=$(date +'%m/%d/%Y')
	[[ -z "$saved" || "$saved" != "$today" ]]
}

env_check_updates() {
	# Same calendar day: do not ping and do not call GitHub.
	env_updates_due || return 0

	if ! ping -c 1 google.com &>/dev/null; then
		ECHO_WARN_YELLOW "No internet connection. Skipping update check."
		return 0
	fi

	if [[ -z "${ENV_UPDATES:-}" ]]; then
		check_env_version "daily"
	elif [[ $ENV_UPDATES == "Everything up-to-date" ]]; then
		ENV_UPDATES=""
	fi
}
