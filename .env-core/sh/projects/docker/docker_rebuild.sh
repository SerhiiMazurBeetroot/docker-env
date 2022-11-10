#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_rebuild() {
    get_existing_domains "======= REBUILD project ======="

    get_project_dir "skip_question"

    if [ -f $PROJECT_DOCKER_DIR/docker-compose.yml ]; then
        docker-compose -f $PROJECT_DOCKER_DIR/docker-compose.yml up -d --force-recreate -V --no-deps --build
    fi
}
