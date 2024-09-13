#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

replace_variables() {
	if [ -f $PROJECT_DOCKER_DIR/docker-compose.yml ]; then
		sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' $PROJECT_DOCKER_DIR/docker-compose.yml
	fi

	if [ -f $PROJECT_DOCKER_DIR/docker-compose.override.yml ]; then
		sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' $PROJECT_DOCKER_DIR/docker-compose.override.yml
	fi
}

docker_compose_runner() {
	local COMMAND=$1
	local DIR_DOCKER=$2

	if [[ "$DIR_DOCKER" == *"nginx"* ]]; then
		DIR_DOCKER=$DIR_DOCKER
		DIR_ENV=../../
	elif [[ "$DIR_DOCKER" == *"ngrok"* ]]; then
		DIR_DOCKER=$DIR_DOCKER
		DIR_ENV=../../
	else
		DIR_DOCKER=$PROJECT_DOCKER_DIR
		DIR_ENV=../../../
	fi

	cd $DIR_DOCKER || exit
	($DOCKER_COMPOSE_CMD $COMMAND)
	cd $DIR_ENV
}

docker_official_image_exists() {
	ECHO_YELLOW "Cheking docker image exists: $1"

	# First check local image
	exist=$(docker image inspect "$1" >/dev/null 2>&1 && echo yes || echo no)

	# Second check FILE_DOCKER_HUB
	if [[ -f $FILE_DOCKER_HUB ]]; then
		remote_image_exist=$(awk '/'"$1"'/{print $1}' "$FILE_DOCKER_HUB")
		[[ ! "$remote_image_exist" ]] && exist=no || exist=yes
	fi

	# Only after than check remote (increase limit)
	if [[ "$exist" == "no" ]]; then
		exist=$(docker manifest inspect "$1" >/dev/null 2>&1 && echo yes || echo no)
	fi

	if [[ "$exist" == "no" ]]; then
		WP_VERSION=$WP_PREV_VER
	else
		WP_VERSION=$WP_LATEST_VER

		# Save image to FILE_DOCKER_HUB
		if [ ! "$remote_image_exist" ]; then
			echo "$1" >>"$FILE_DOCKER_HUB"
		fi
	fi
}

get_docker_ip() {
	if [ -n "$1" ]; then
		export DOCKER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' b4002c9c6fdb)
	fi
}
