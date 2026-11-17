#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_delete_project() {
	docker_require_project_context "======= DELETE project ========" || return 1

	if ! database_snapshot_before_delete; then
		ECHO_ERROR "Delete cancelled. The database snapshot failed."
		return 1
	fi

	INSTANCES_STATUS="remove"
	ECHO_YELLOW "Deleting site [$PROJECT_ROOT_DIR]"
	fix_permissions || true
	docker_stop || true
	nextjs_local_remove || true

	local images volumes item

	images=""
	if [[ -n "${DOCKER_CONTAINER_APP:-}" ]]; then
		images=$(docker image ls --format '{{.Repository}} {{.ID}}' 2>/dev/null | docker_names_matching "$DOCKER_CONTAINER_APP" || true)
	fi

	if [[ -n "$images" ]]; then
		while IFS= read -r item; do
			[[ -n "$item" ]] || continue
			if docker rmi --force "$item" >/dev/null; then
				ECHO_YELLOW "Deleted image $item"
			else
				ECHO_WARN_YELLOW "Could not delete image $item"
			fi
		done <<<"$images"
	else
		ECHO_YELLOW "No project image to delete"
	fi

	volumes=""
	if [[ -n "${DOCKER_VOLUME_DB:-}" ]]; then
		volumes=$(docker volume ls --format '{{.Name}}' 2>/dev/null | docker_names_matching "$DOCKER_VOLUME_DB" || true)
	fi

	if [[ -n "$volumes" ]]; then
		while IFS= read -r item; do
			[[ -n "$item" ]] || continue
			if docker volume rm "$item" >/dev/null; then
				ECHO_YELLOW "Deleted volume $item"
			else
				ECHO_WARN_YELLOW "Could not delete volume $item"
			fi
		done <<<"$volumes"
	else
		ECHO_YELLOW "No project volume to delete"
	fi

	delete_site_data || return 1
	notice_windows_host rem
	ECHO_SUCCESS "Project deleted [${DOMAIN_NAME:-}]"
}

docker_delete() {
	get_existing_domains "======== DELETE project =======" || return 1

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
				return 1
				;;

			*) echo "Please answer [y/n]" ;;
			esac
		done
	else
		ECHO_ERROR "Site DIR does not exist: $PROJECT_ROOT_DIR"
		delete_site_data || return 1
	fi
}
