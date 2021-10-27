#!/bin/bash

set -o errexit #to stop the script when an ECHO_ERROR occurs
set -o pipefail

nginx_proxy () {
    if [ ! -d "./env-core/nginx" ];
    then
        ECHO_ERROR "Nginx folder does not exist"
        ECHO_ERROR "Make sure folder was not deleted"
    else
        if [ -f "./env-core/nginx/docker-compose.yml" ];
        then
            if [ "$(docker ps --format '{{.Names}}' | grep nginx-proxy)" ]
            then
                EMPTY_LINE
                ECHO_SUCCESS "Nginx-proxy already setup and running"
                EMPTY_LINE
            else
                ECHO_YELLOW "Container is not running"

                [ ! "$(docker volume ls | grep ssl-certs)" ] && docker volume create --name ssl-certs
                if [ ! "$(docker network ls | grep dockerwp)" ]
                then    
                    docker network create dockerwp
                    docker_nginx_start
                else
                    docker_nginx_start
                fi
                ECHO_SUCCESS "Container started"
            fi
        else
            ECHO_ERROR "Docker compose file for nginx-proxy not here"
            echo "Make sure file is not deleted"
            if [ "$(git status| grep nginx/docker-compose.yml)" ]
            then
                ECHO_WARN_RED "File has been deleted"
                git checkout -- nginx/docker-compose.yml
                ECHO_SUCCESS "File has been restored"
                if [ ! "$(docker network ls | grep dockerwp)" ]
                then
                    docker network create dockerwp
                    docker_nginx_start
                else
                    docker_nginx_start
                    if [ "$(docker ps -a | grep nginx-proxy)" ]
                    then
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
