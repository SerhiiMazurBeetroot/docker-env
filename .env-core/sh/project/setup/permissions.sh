#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

fix_permissions() {
	check_domain_exists

	if [[ $DOMAIN_EXISTS == 1 ]]; then
		case ${PROJECT_TYPE:-} in
		"wordpress" | "bedrock" | "wpnextjs")
			fix_permissions_wp
			;;
		*)
			fix_permissions_project_root
			;;
		esac
	else
		ECHO_ERROR "Site not exists"
	fi
}

fix_permissions_wp() {
	EMPTY_LINE
	ECHO_YELLOW "Fixing Permissions [wp], this can take a while! [$PROJECT_ROOT_DIR]"

	if [ "$(docker ps --format '{{.Names}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)')" ]; then
		docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'chown -R www-data:www-data /var/www/html/'
		docker exec -i "$DOCKER_CONTAINER_APP" sh -c 'chmod -R ug+rwX /var/www/html/'
	else
		ECHO_ERROR "Docker container doesn't exist [fix_permissions_wp] [$PROJECT_ROOT_DIR]"
	fi

	if [[ $OSTYPE == "linux" ]]; then
		if [[ -d "$PROJECT_WP_CONTENT_DIR" ]]; then
			local writable_dir
			for writable_dir in uploads cache themes plugins; do
				if [[ -d "$PROJECT_WP_CONTENT_DIR/$writable_dir" ]]; then
					sudo chmod -R ug+rwX "$PROJECT_WP_CONTENT_DIR/$writable_dir"
				fi
			done
		fi
	fi

	if [[ ${SETUP_ACTION:-} == "create" ]]; then
		git_config_fileMode
	fi
}

fix_permissions_project_root() {
	if [[ $OSTYPE == "linux" && -d "$PROJECT_ROOT_DIR" ]]; then
		EMPTY_LINE
		ECHO_YELLOW "Fixing Permissions [root], this can take a while! [$PROJECT_ROOT_DIR]"
		sudo chmod -R ug+rwX "$PROJECT_ROOT_DIR"
	fi
}
