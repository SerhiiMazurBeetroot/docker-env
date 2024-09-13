#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_start() {
    stopped_projects_list "======== START project ========"

    if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)')" ]; then
        ECHO_WARN_RED "Containers already running for this domain"
        project_services_menu
    else
        if [[ "$(docker image ls --format '{{.Repository}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)')" ]] && [ "$(docker volume ls --format '{{.Name}}' | grep -E '(^|_|-)'$DOCKER_VOLUME_DB'($)')" ]; then
            ECHO_SUCCESS "Site image and volume found"

            if [ -f $PROJECT_DOCKER_DIR/docker-compose.yml ]; then
                ECHO_YELLOW "Starting docker containers for this site"

                docker_compose_runner "up -d"

                ECHO_GREEN "Restarted now."
                docker_nginx_restart

                fix_permissions
            else
                ECHO_ERROR "Docker-compose file for this site was not found"
                ECHO_ERROR "Cannot restart site, in this case delete and start again"
            fi
        else
            # In case the docker images were deleted
            ECHO_ERROR "Site image or volume was not found"
            ECHO_YELLOW "Checking for Docker-compose file exist"

            if [ -d "$PROJECT_DOCKER_DIR" ]; then
                DOCKER_FILES=($(find $PROJECT_DOCKER_DIR -type f -name '*.yml'))

                if [ -f "$DOCKER_FILES" ]; then
                    echo "Starting Container"
                    docker_compose_runner "up -d"
                else
                    ECHO_ERROR "Docker-compose file not found"
                    exit
                fi
            else
                ECHO_ERROR "DOCKER_DIR not found"
            fi
        fi
    fi
}
