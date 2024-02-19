#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

env_settings() {
    check_env_version "$@"

    while true; do
        EMPTY_LINE
        ECHO_CYAN "===== Settings ===="
        ECHO_YELLOW "0 - Return to main menu"
        ECHO_KEY_VALUE "1 - ENV_UPDATES:" "$ENV_UPDATES"
        ECHO_KEY_VALUE "2 - ENV_THEME:" "$ENV_THEME"
        ECHO_KEY_VALUE "3 - Versions"

        settings=$(GET_USER_INPUT "select_one_of")

        case $settings in
        0)
            main_actions
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
    ENV_THEME=$(awk '/ENV_THEME/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_THEME='//')
    ENV_VERSION=$(awk '/ENV_VERSION/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_VERSION='//')

    if [ "$ENV_THEME" = 'dark' ]; then
        settings=("ENV_THEME=light")
    else
        settings=("ENV_THEME=dark")
    fi

    save_settings "${settings[@]}"
    exit
}

check_env_version() {
    env_migration
    add_alias

    ENV_THEME=$(awk '/ENV_THEME/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_THEME='//')
    ENV_VERSION=$(awk '/ENV_VERSION/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_VERSION='//')
    ENV_DATE_CHECK=$(awk '/ENV_DATE_CHECK/{print $1}' "$FILE_SETTINGS" | sed 's/'ENV_DATE_CHECK='//')
    DATE_NOW=$(date +'%m/%d/%Y')

    if [[ $ENV_DATE_CHECK == '' ]]; then
        check_git_version

        #First setup
        echo "ENV_DATE_CHECK=$DATE_NOW" >>"$FILE_SETTINGS"
    else
        #Run only once a day
        if [[ $ENV_DATE_CHECK != $DATE_NOW || $1 != 'daily' ]]; then
            check_git_version

            #Replace ENV_DATE_CHECK
            sed -i -e '/ENV_DATE_CHECK/d' "$FILE_SETTINGS"
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
}

core_version() {
    if [[ $CORE_VER_CUR != $CORE_VERSION || $CORE_VER_CUR == '' ]]; then
        save_settings "CORE_VERSION=$CORE_VERSION"
    fi
}

env_check_updates() {
    # Notice about updates to main menu
    if [[ ! $ENV_UPDATES ]]; then
        check_env_version "daily"
    elif [[ $ENV_UPDATES == "Everything up-to-date" ]]; then
        ENV_UPDATES=""
    fi
}
