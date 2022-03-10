#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

replace_old_settings_file () {
    #old case with settings file
    ENV_THEME=$(awk '/''/{print $1}' "$FILE_SETTINGS" | tail -n 1);
    ENV_VERSION=$(awk '/''/{print $3}' "$FILE_SETTINGS" | tail -n 1);

    if [[ $ENV_THEME != '' && $ENV_VERSION != '' ]];
    then 
        save_settings "$ENV_THEME"
    fi
}
