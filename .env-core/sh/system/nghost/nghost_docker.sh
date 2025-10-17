#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

export DIR_NGHOST="$DIR_SYSTEM/nghost"

docker_nghost_setup() {
	if [ ! -d "$DIR_NGHOST" ]; then
		ECHO_ERROR "NgHost folder does not exist"
		ECHO_ERROR "Make sure folder was not deleted"
	else
		if [ -f "$DIR_NGHOST/docker-compose.yml" ]; then
			docker_nghost_start
		else
			ECHO_ERROR "Docker compose file for NgHost not here"
		fi
	fi
}

docker_nghost_start() {
	if [ $NGINX_EXISTS -eq 0 ]; then
		docker_compose_runner "up -d" "$DIR_NGHOST"

		ECHO_SUCCESS "NgHost started"
	else
		ECHO_ERROR "NgHost container not running"
		nginx_menu
	fi
}

docker_nghost_stop() {
	if [ $NGINX_EXISTS -eq 1 ]; then
		docker_compose_runner "down" "$DIR_NGHOST"
		ECHO_SUCCESS "NgHost container stopped"
	else
		ECHO_ERROR "Nginx container not running"
		nginx_menu
	fi
}

docker_nghost_restart() {
	if [ $NGINX_EXISTS -eq 1 ]; then
		docker_compose_runner "restart" "$DIR_NGHOST"
	else
		ECHO_ERROR "Nginx container not running"
		nginx_menu
	fi
}

docker_nghost_rebuild() {
	docker_compose_runner "up -d --force-recreate --no-deps --build" "$DIR_NGHOST"
}
