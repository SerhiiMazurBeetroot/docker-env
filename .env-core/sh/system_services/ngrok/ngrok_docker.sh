#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

export DIR_NGROK="$ENV_DIR/.env-core/ngrok"
NGROK_CONFIG_FILE="$DIR_NGROK/.ngrok2/ngrok.yml"
NGROK_ENV_FILE="$DIR_NGROK/.env"

docker_ngrok_setup() {
    ECHO_SUCCESS "docker_ngrok_setup: $DIR_NGROK"

    if [ ! -d "$DIR_NGROK" ]; then
        ECHO_ERROR "Ngrok folder does not exist"
        ECHO_ERROR "Make sure folder was not deleted"
    else

        if [ -f "$DIR_NGROK/docker-compose.yml" ]; then

            # Set the authtoken
            ngrok_read_env
            sed -i "s/^  authtoken:.*$/  authtoken: '$NGROK_AUTH'/g" "$NGROK_CONFIG_FILE"

            docker_ngrok_start

            ECHO_SUCCESS "Container started"
        else
            ECHO_ERROR "Docker compose file for Ngrok not here"
        fi
    fi
}

docker_ngrok_start() {
    if [ $NGINX_EXISTS -eq 1 ]; then
        docker_compose_runner "up -d" "$DIR_NGROK"
        ECHO_SUCCESS "Ngrok started"
    else
        ECHO_ERROR "Ngrok container not running"
        nginx_menu
    fi
}

docker_ngrok_stop() {
    if [ $NGINX_EXISTS -eq 1 ]; then
        docker_compose_runner "down" "$DIR_NGROK"
        ECHO_SUCCESS "Ngrok container stopped"
    else
        ECHO_ERROR "Nginx container not running"
        nginx_menu
    fi
}

docker_ngrok_restart() {
    if [ $NGINX_EXISTS -eq 1 ]; then
        docker_compose_runner "restart" "$DIR_NGROK"
    else
        ECHO_ERROR "Nginx container not running"
        nginx_menu
    fi
}

docker_ngrok_rebuild() {
    docker_compose_runner "up -d --force-recreate --no-deps --build" "$DIR_NGROK"
}

ngrok_save_token() {
    ngrok_read_env

    read -rp "Enter token: " NGROK_AUTH

    if [[ $NGROK_AUTH != '' ]]; then
        sed -i "s/^NGROK_AUTH=.*$/NGROK_AUTH='$NGROK_AUTH'/g" "$NGROK_ENV_FILE"
        sed -i "s/^  authtoken:.*$/  authtoken: '$NGROK_AUTH'/g" "$NGROK_CONFIG_FILE"
    fi
}

ngrok_add_endpoint() {

    [[ "$DOMAIN_NAME" == '' ]] && running_projects_list "======= Add new endpoint ======="
    if [[ $DOMAIN_NAME != '' ]]; then

        if grep -q "name: ${DOMAIN_NAME}" "$NGROK_CONFIG_FILE"; then
            ECHO_WARN_RED "Endpoint for [${DOMAIN_NAME}] already exists in the ngrok.yml"
        else
            ENDPOINT_TEMPLATE="  # ${DOMAIN_FULL} START #
  - name: ${DOMAIN_NAME}
    description: ${DOMAIN_NAME} description
    metadata: ${DOMAIN_NAME} metadata
    upstream:
      url: ${DOCKER_CONTAINER_APP}:80
      protocol: http1
  # ${DOMAIN_NAME} END #"
            printf "%s\n" "$ENDPOINT_TEMPLATE" >>"$NGROK_CONFIG_FILE"

            ECHO_SUCCESS "Endpoint for ${DOMAIN_NAME} added"
        fi
    fi

    unset_variables
    docker_ngrok_restart
}

ngrok_delete_endpoint() {

    [[ "$DOMAIN_NAME" == '' ]] && running_projects_list "======= Add new endpoint ======="
    if [[ $DOMAIN_NAME != '' ]]; then
        if grep -q "name: ${DOMAIN_NAME}" "$NGROK_CONFIG_FILE"; then
            sed -i "/# ${DOMAIN_FULL} START #/,/# ${DOMAIN_FULL} END #/d" "$NGROK_CONFIG_FILE"

            ECHO_SUCCESS "Endpoint for ${DOMAIN_NAME} deleted"
        else
            ECHO_WARN_RED "Endpoint for [${DOMAIN_NAME}] already exists in the ngrok.yml"
        fi
    fi

    unset_variables
    docker_ngrok_restart
}

ngrok_read_env() {
    source $NGROK_ENV_FILE
}
