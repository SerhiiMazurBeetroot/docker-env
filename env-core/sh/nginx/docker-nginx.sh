#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_nginx_start () {
    docker-compose -f ./env-core/nginx/docker-compose.yml up -d
}

docker_nginx_stop () {
    if [ "$(docker ps -a | grep "nginx-proxy")" ];
    then
        docker-compose -f ./env-core/nginx/docker-compose.yml down
    else
        ECHO_ERROR "Nginx container not running"
    fi
}

docker_nginx_restart () {
    if [ "$(docker ps -a | grep "nginx-proxy")" ];
    then
        docker-compose -f ./env-core/nginx/docker-compose.yml restart
    else
        ECHO_ERROR "Nginx container not running"
    fi
}

docker_nginx_rebuild () {
    docker-compose -f ./env-core/nginx/docker-compose.yml up -d --force-recreate --no-deps --build
}
