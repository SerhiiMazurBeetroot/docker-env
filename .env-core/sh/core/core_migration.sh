#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

env_migration() {
    CORE_VER_CUR=$(awk '/CORE_VERSION/{print $1}' "$FILE_SETTINGS" | sed 's/'CORE_VERSION='//')

    if [[ $CORE_VER_CUR == '' ]]; then
        #case v.1.0.0 => v.2.0.0
        replace_old_settings_file
        replace_old_wp_instances_file
        replace_dir_projects_to_wordpress
        replace_docker_compose
        core_version
    fi
}

replace_old_settings_file() {
    #old case with settings file
    ENV_THEME=$(awk '/''/{print $1}' "$FILE_SETTINGS" | tail -n 1)
    ENV_VERSION=$(awk '/''/{print $3}' "$FILE_SETTINGS" | tail -n 1)

    if [[ $ENV_THEME != '' && $ENV_VERSION != '' ]]; then
        ECHO_YELLOW "Replacing settings file ..."

        save_settings "$ENV_THEME"
    fi
}

replace_old_wp_instances_file() {
    if [ -f "./wp-instances.log" ]; then
        ECHO_YELLOW "Replacing FILE_INSTANCES ..."

        mv "./wp-instances.log" "./.env-core/instances.log"
        while read line; do
            if [[ $line == *"DOMAIN_NAME"* ]]; then
                sed -i -e "s/$line/3309 \| STATUS \| DOMAIN_NAME \| DOMAIN_FULL \| DB_NAME \| DB_TYPE \| PROJECT_TYPE \|/g" $FILE_INSTANCES
            else
                sed -i -e "s/$line/$line MYSQL \| wordpress \|/g" $FILE_INSTANCES
            fi

        done <"$FILE_INSTANCES"

        #Replace "Protocol https" to "Status active"
        while read line; do
            sed -i -e "s/https/active/g" $FILE_INSTANCES
        done <"$FILE_INSTANCES"
    fi
    EMPTY_LINE
}

replace_dir_projects_to_wordpress() {
    if [ -d "./projects" ]; then
        PROJECT_TYPE="projects"

        echo 'projects exists'
        docker_stop_all

        mv ./projects ./wordpress

        unset_variables "PROJECT_TYPE"
    fi
}

replace_docker_compose() {
    DOCKER_FILES=($(find . -type f -name 'docker-compose.*.yml'))

    if [[ $DOCKER_FILES ]]; then
        ECHO_YELLOW "Don't worry, it's just a migration process"
        ECHO_YELLOW "Replacing docker-compose files ..."

        for DOCKER_FILE in "${DOCKER_FILES[@]}"; do
            echo $DOCKER_FILE | while read FILENAME; do

                # Exclude files from templates folder
                if [[ $FILENAME != *".env-core/templates"* ]]; then
                    NEW_FILENAME="$(echo ${FILENAME} | sed -e 's/docker-compose.*.yml/docker-compose.yml/')"
                    ECHO_KEY_VALUE "$FILENAME   =>   " "$NEW_FILENAME"

                    mv "${FILENAME}" "${NEW_FILENAME}"

                    #Replace old path for adminer.php
                    DOCKER_DIR="$(echo ${FILENAME} | sed -e 's/docker-compose.*.yml//')"
                    cp -rf ./.env-core/templates/wordpress/adminer.php.example $DOCKER_DIR/adminer.php
                    sed -i -e 's/.\/..\/..\/..\/env-core\/templates\/database\/adminer-template:/.\/..\/wp-docker\/adminer.php:/g' $NEW_FILENAME
                fi
            done
        done
        EMPTY_LINE
    fi
}
