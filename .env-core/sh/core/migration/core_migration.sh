#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

env_migration() {
    CORE_VER_CUR=$(awk '/CORE_VERSION/{print $1}' "$FILE_SETTINGS" | sed 's/'CORE_VERSION='//')

    move_dir_data

    if [[ $CORE_VER_CUR == '' ]]; then
        #case v.1.0.0 => v.2.0.0
        replace_old_settings_file
        replace_wp_instances_file_1_0
        replace_dir_projects_to_wordpress
        replace_docker_compose
        delete_visible_envcore_dir
    fi

    if [[ $CORE_VER_CUR == '2.0.0' ]]; then
        replace_wp_instances_file_2_0
    fi

    core_version
}

move_dir_data() {
    if [ -f "$ENV_DIR/.env-core/instances.log" ]; then
        ECHO_YELLOW "Replacing FILE_INSTANCES ..."

        mv "$ENV_DIR/.env-core/settings.log" $FILE_SETTINGS
        mv "$ENV_DIR/.env-core/instances.log" $FILE_INSTANCES
    fi
}

delete_visible_envcore_dir() {
    if [ -d "env-core" ]; then
        rm -rf env-core
    fi
}
