#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

replace_variables() {

  if [ -f $PROJECT_DOCKER_DIR/Dockerfile ]; then
    sed -i -e 's/{WP_VERSION}/'$WP_VERSION'/g' $PROJECT_DOCKER_DIR/Dockerfile
    sed -i -e 's/{PHP_VERSION}/'$PHP_VERSION'/g' $PROJECT_DOCKER_DIR/Dockerfile
  fi

  if [ -f $PROJECT_DOCKER_DIR/docker-compose.yml ]; then
    sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' $PROJECT_DOCKER_DIR/docker-compose.yml
  fi

  if [ -f $PROJECT_DOCKER_DIR/docker-compose.override.yml ]; then
    sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' $PROJECT_DOCKER_DIR/docker-compose.override.yml
  fi
}
