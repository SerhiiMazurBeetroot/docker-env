#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_nginx_setup() {
    if [ ! -d "$DIR_NGINX" ]; then
        ECHO_ERROR "Nginx folder does not exist"
        ECHO_ERROR "Make sure folder was not deleted"
    else
        if [ -f "$DIR_NGINX/docker-compose.yml" ]; then
            if [ $NGINX_EXISTS -eq 1 ]; then
                ECHO_ATTENTION "Nginx already setup and running"
            else
                ECHO_YELLOW "Container is not running"

                [ ! "$(docker volume ls | grep ssl-certs)" ] && docker volume create --name ssl-certs
                if [ ! "$(docker network ls | grep dockerwp)" ]; then
                    docker network create dockerwp
                    docker_nginx_start
                else
                    docker_nginx_start
                fi

                #Fix certs DIR permissions
                if [[ $OSTYPE != "windows" ]]; then
                    sudo chmod -R 777 .env-core/nginx/certs-root/
                fi
                ECHO_SUCCESS "Container started"
            fi
        else
            ECHO_ERROR "Docker compose file for nginx-proxy not here"
            echo "Make sure file is not deleted"
            if [ "$(git status | grep nginx/docker-compose.yml)" ]; then
                ECHO_WARN_RED "File has been deleted"
                git checkout -- nginx/docker-compose.yml
                ECHO_SUCCESS "File has been restored"
                if [ ! "$(docker network ls | grep dockerwp)" ]; then
                    docker network create dockerwp
                    docker_nginx_start
                else
                    docker_nginx_start
                    if [ $NGINX_EXISTS -eq 1 ]; then
                        ECHO_SUCCESS "Container started"
                    else
                        ECHO_ERROR "Problem starting container"
                    fi
                fi
            else
                ECHO_ERROR "Recheck why docker-compose is not in folder"
            fi
        fi
    fi
}

docker_nginx_start() {
    if [ $NGINX_EXISTS -eq 0 ]; then
        docker_compose_runner "up -d" "$DIR_NGINX"
        ECHO_SUCCESS "Nginx started"
    else
        ECHO_ATTENTION "Nginx already setup and running"
    fi
}

docker_nginx_stop() {
    if [ $NGINX_EXISTS -eq 1 ]; then
        docker_compose_runner "down" "$DIR_NGINX"
        ECHO_SUCCESS "Nginx container stopped"
    else
        ECHO_ERROR "Nginx container not running"
    fi
}

docker_nginx_restart() {
    if [ $NGINX_EXISTS -eq 1 ]; then
        docker_compose_runner "restart" "$DIR_NGINX"
    else
        ECHO_ERROR "Nginx container not running"
    fi
}

docker_nginx_rebuild() {
    docker_compose_runner "up -d --force-recreate --no-deps --build" "$DIR_NGINX"
}

docker_nginx_container() {
    if [ "$(docker ps --format '{{.Names}}' | grep -E '(^)nginx-proxy($)')" ]; then
        NGINX_EXISTS=1
    else
        NGINX_EXISTS=0
    fi
}

docker_nginx_resetup() {
    if [ $NGINX_EXISTS -eq 1 ]; then
        docker_nginx_stop

        [ "$(docker volume ls | grep ssl-certs)" ] && docker volume rm "ssl-certs" && ECHO_YELLOW "Deleting Volume ssl-certs" || echo "Volume ssl-certs not found"

        rm -rf .env-core/nginx/certs-root

        docker_nginx_container
        docker_nginx_setup
    else
        ECHO_ERROR "Nginx container not running"
    fi
}
