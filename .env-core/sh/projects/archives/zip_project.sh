#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

zip_project() {
	get_existing_domains "======== ZIP project ======="

	get_project_dir "skip_question"

	if [ -d $PROJECT_ROOT_DIR ]; then
		#First of all save DB
		database_auto_backup

	    #Delete "vendor" and "node_modules"
		if [ -d $PROJECT_ROOT_DIR/vendor ]; then
			VENDOR_DIR=($(find $PROJECT_ROOT_DIR/vendor -type d -name "vendor"))

			for i in "${!VENDOR_DIR[@]}"; do
				rm -rf ${VENDOR_DIR[$i]}
			done
		fi

		NM_DIR=($(find $PROJECT_ROOT_DIR -type d -name "node_modules"))
		if [ "$NM_DIR" ]; then
			for i in "${!NM_DIR[@]}"; do
				rm -rf ${NM_DIR[$i]}
			done
		fi

		#Then keep archiving
		filename="archive_"$PROJECT_ARCHIVE_DIR"_$(date '+%d-%m-%y').zip"

		cd $PROJECT_DIR
		zip -r $filename $DOMAIN_FULL
		cd ..

		fix_permissions
		docker_stop

		if [[ $(docker image ls --format '{{.Repository}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)') ]]; then
			EMPTY_LINE
			imageid=$(docker image ls --format '{{.Repository}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)')
			[ -n "$imageid" ] && docker rmi "$imageid" --force && ECHO_YELLOW "Deleting images" || ECHO_WARN_YELLOW "Image not found"
		else
			ECHO_ERROR "Docker image does not exist"
		fi

		if [ $(docker volume ls --format '{{.Name}}' | grep -E '(^|_|-)'$DOCKER_VOLUME_DB'($)') ]; then
			EMPTY_LINE
			volumename=$(docker volume ls --format '{{.Name}}' | grep -E '(^|_|-)'$DOCKER_VOLUME_DB'($)')
			[ -n "$volumename" ] && docker volume rm "$volumename" && ECHO_YELLOW "Deleting Volume" || echo "Volume not found"
		else
			ECHO_ERROR "Docker volume does not exist"
		fi

		delete_site_data

		EMPTY_LINE
		ECHO_SUCCESS "Archive $DOMAIN_FULL successfully created."
	else
		ECHO_ATTENTION "Directory name doesn't exists."
	fi
}
