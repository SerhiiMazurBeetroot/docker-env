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

    # Read existing settings from file into an associative array
    declare -A existing_settings
    if [[ -f "$FILE_SETTINGS" ]]; then
        while IFS='=' read -r key value; do
            existing_settings["$key"]=$value
        done <"$FILE_SETTINGS"
    fi

    # Update existing settings and add new settings to the associative array
    for setting in "${settings[@]}"; do
        key="${setting%=*}"
        value="${setting#*=}"
        existing_settings["$key"]=$value
    done

    # Save the updated settings to the file
    printf "%s\n" "${!existing_settings[@]}" | while IFS= read -r key; do
        echo "$key=${existing_settings[$key]}"
    done >"$FILE_SETTINGS"
}

core_version() {
    if [[ $CORE_VER_CUR != $CORE_VERSION || $CORE_VER_CUR == '' ]]; then
        save_settings "CORE_VERSION=$CORE_VERSION"
    fi
}
