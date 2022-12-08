#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_restart() {
    [[ "$DOMAIN_NAME" == '' ]] && running_projects_list "======= RESTART project ======="

    get_project_dir "skip_question"

    if [ "$(docker ps --format '{{.Names}}' | grep -E '(^)'$DOCKER_CONTAINER_APP'($)')" ]; then
        [ -f $PROJECT_DOCKER_DIR/docker-compose.yml ] && docker-compose -f $PROJECT_DOCKER_DIR/docker-compose.yml restart

        docker_nginx_restart
    else
        ECHO_ERROR "Docker container doesn't exist [$PROJECT_ROOT_DIR]"
    fi
}
