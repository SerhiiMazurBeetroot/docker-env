#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_delete_project() {
	docker_require_project_context "======= DELETE project ========" || return 1

	INSTANCES_STATUS="remove"
	ECHO_YELLOW "Deleting site [$PROJECT_ROOT_DIR]"
	fix_permissions || true
	docker_stop || true

	if [[ -n "${DOCKER_CONTAINER_APP:-}" && $(docker image ls --format '{{.Repository}}' | grep -E '(^|_|-)'"$DOCKER_CONTAINER_APP"'($)') ]]; then
		imageid=$(docker image ls --format '{{.Repository}}' | grep -E '(^|_|-)'"$DOCKER_CONTAINER_APP"'($)')
		[ -n "$imageid" ] && docker rmi "$imageid" --force && ECHO_YELLOW "Deleting images" || ECHO_WARN_YELLOW "Image not found"
	else
		ECHO_YELLOW "No project image to delete"
	fi

	if [[ -n "${DOCKER_VOLUME_DB:-}" && $(docker volume ls --format '{{.Name}}' | grep -E '(^|_|-)'"$DOCKER_VOLUME_DB"'($)') ]]; then
		volumename=$(docker volume ls --format '{{.Name}}' | grep -E '(^|_|-)'"$DOCKER_VOLUME_DB"'($)')
		[ -n "$volumename" ] && docker volume rm "$volumename" && ECHO_YELLOW "Deleting Volume" || echo "Volume not found"
	else
		ECHO_YELLOW "No project volume to delete"
	fi

	delete_site_data
	notice_windows_host rem
	ECHO_SUCCESS "Project deleted [${DOMAIN_NAME:-}]"
}

docker_delete() {
	get_existing_domains "======== DELETE project ======="

	if [ -d "$PROJECT_ROOT_DIR" ]; then
		EMPTY_LINE
		ECHO_ATTENTION "You can't restore the site after it has been deleted."
		ECHO_ATTENTION "This operation will remove the localhost containers, volumes, and the WordPress core files."

		while true; do
			ECHO_WARN_YELLOW "Removing now... [$PROJECT_ROOT_DIR]"
			yn=$(GET_USER_INPUT "question" "Do you wish to proceed?" "y")

			case $yn in
			[Yy]*)
				EMPTY_LINE
				docker_delete_project
				break
				;;
			[Nn]*)
				unset_variables
				project_services_menu
				;;

			*) echo "Please answer [y/n]" ;;
			esac
		done
	else
		ECHO_ERROR "Site DIR does not exist: $PROJECT_ROOT_DIR"
		delete_site_data
	fi
}
