#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_stop() {
    get_project_dir "skip_question"

    if [ "$(docker ps --format '{{.Names}}' | grep -P '(^)'$DOCKER_CONTAINER_APP'($)')" ]; then

        if [ -f $PROJECT_DOCKER_DIR/docker-compose.yml ]; then
            docker-compose -f $PROJECT_DOCKER_DIR/docker-compose.yml down
        fi

        docker_nginx_restart

        ECHO_SUCCESS "Docker container stopped [$DOMAIN_FULL]"
    else
        ECHO_ERROR "Docker container doesn't exist [$DOMAIN_FULL]"
    fi
}
