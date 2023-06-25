#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

env_update_repo() {
    if repo_exists "$MAIN_REPO"; then
        # Repository does not exist.
        MAIN_REPO=$OLD_REPO
    else
        # Repository exists.
        MAIN_REPO=$MAIN_REPO
    fi
}

fix_old_compose_project_name() {
    ECHO_YELLOW "Don't worry, it's just a migration process"
    ECHO_YELLOW "Replacing old vars COMPOSE_PROJECT_NAME ..."

    DOCKER_FILES=($(find . -type f -name '.env'))

    if [[ $DOCKER_FILES ]]; then
        docker_stop_all

        for DOCKER_FILE in "${DOCKER_FILES[@]}"; do
            if [[ $FILENAME != *".env-core/templates"* ]]; then
                DOMAIN_FULL=$(awk -F= '/COMPOSE_PROJECT_NAME/{gsub(/'"'"'/, "", $2); print $2}' "$DOCKER_FILE")

                get_compose_project_name

                sed -i "s/^COMPOSE_PROJECT_NAME='.*/COMPOSE_PROJECT_NAME='$COMPOSE_PROJECT_NAME'/" "$DOCKER_FILE"
            fi

        done
    fi

}
