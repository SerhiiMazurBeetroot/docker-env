#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

wp_multisite_convert() {
	if [ "$DOMAIN_NAME" == '' ]; then
		running_projects_list "======= Enabling multisite ======"
	fi

	IS_MULTISITE=$(awk '/WP_ALLOW_MULTISITE=/{print $1}' "$PROJECT_DOCKER_DIR"/.env | tr -d WP_ALLOW_MULTISITE=)
	if [ "$IS_MULTISITE" == 0 ]; then
		wp_multisite_htaccess
		wp_multisite_env

		docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp core multisite-convert'

		# Set pretty urls
		docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp rewrite structure '/%postname%/' --hard --allow-root'
		docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'wp rewrite flush --hard --allow-root'

		docker_rebuild
	else
		ECHO_WARN_YELLOW "This site is already a multisite"
	fi

}

wp_multisite_htaccess() {
	containerId=$(docker inspect -f '{{.Id}}' $DOCKER_CONTAINER_APP)
	docker cp $PROJECT_DOCKER_DIR/htaccess.multisite $containerId:/var/www/html/.htaccess
}

wp_multisite_env() {
	sed -i -e 's/WP_ALLOW_MULTISITE=0/WP_ALLOW_MULTISITE=1/g' $PROJECT_DOCKER_DIR/.env
}
