#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_stop_all() {
    ECHO_YELLOW "Stoping all containers..."

    string=$(awk '{print $5}' "$FILE_INSTANCES" | tail -n +2)
    OptionList=($string)
    for i in "${!OptionList[@]}"; do
        DOMAIN_NAME="${OptionList[$i]}"
        get_project_dir "skip_question"

        database_auto_backup

        if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)')" ]; then

            if [ -d "$PROJECT_DOCKER_DIR" ]; then
                DOCKER_FILES=($(find $PROJECT_DOCKER_DIR -type f -name '*.yml'))

                [ -f "$DOCKER_FILES" ] && docker_compose_runner "down"
            fi

            ECHO_SUCCESS "Docker container stopped [$PROJECT_ROOT_DIR]"
        fi
        unset_variables
    done

    docker_nginx_restart
}
