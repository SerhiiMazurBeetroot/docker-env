#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

docker_create_nodejs () {
	unset_variables
	get_domain_name
	check_domain_exists

	if [[ $DOMAIN_EXISTS == 0 ]];
	then
		check_data_before_continue_callback docker_create_nodejs

		ECHO_INFO "Setting up Docker containers for $DOMAIN_FULL"

		#GET PORT
		get_unique_port

		get_project_dir "skip_question"

		print_to_file_instances

		MONGODB_DOCKER_PORT=$(($PORT + 23707)) # TODO: check if this is correct
		MONGODB_LOCAL_PORT=$(($PORT + 3707))
		MONGO_EXPRESS_PORT=$(($PORT + 4771))


		mkdir -p $PROJECT_ROOT_DIR/

		# Copy templates files
		# cp -r ./.env-core/templates/nodejs/* $PROJECT_ROOT_DIR
		rsync -av --exclude=./.env-core/templates/nodejs* ./.env-core/templates/nodejs/ $PROJECT_ROOT_DIR/

		# Rename files
		replace_templates_files

		sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' $PROJECT_ROOT_DIR/.env
		sed -i -e 's/{DOMAIN_FULL}/'$DOMAIN_FULL'/g' $PROJECT_ROOT_DIR/.env
		sed -i -e 's/{PORT}/'$PORT'/g' $PROJECT_ROOT_DIR/.env
		sed -i -e 's/{MONGODB_LOCAL_PORT}/'$MONGODB_LOCAL_PORT'/g' $PROJECT_ROOT_DIR/.env
		sed -i -e 's/{MONGO_EXPRESS_PORT}/'$MONGO_EXPRESS_PORT'/g' $PROJECT_ROOT_DIR/.env

		# mv $PROJECT_ROOT_DIR/docker-compose.yml $PROJECT_ROOT_DIR/docker-compose.yml
		sed -i -e 's/{DOMAIN_NAME}/'$DOMAIN_NAME'/g' $PROJECT_ROOT_DIR/docker-compose.yml

		setup_hosts_file add

		docker-compose -f $PROJECT_ROOT_DIR/docker-compose.yml up -d


	else
		ECHO_ERROR "Site already exists"
		docker_create_nodejs
	fi

}

docker_nodejs_delete () {


	if [ -d $PROJECT_ROOT_DIR ];
	then
		EMPTY_LINE
		ECHO_ATTENTION "You can't restore the site after it has been deleted."
		ECHO_ATTENTION "This operation will remove the localhost containers, volumes, and the WordPress core files."
		while true; do
			ECHO_WARN_YELLOW "Removing now... $DOMAIN_FULL"
			read -rp "$(ECHO_WARN_RED "Do you wish to proceed?") [y/n] " yn
			case $yn in
				[Yy]*)
					ECHO_YELLOW "Deleting site"
					fix_permissions
					docker_stop
					
					if [ $( docker image ls --format '{{.Repository}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)' ) ];
					then
						EMPTY_LINE
						imageid=$( docker image ls --format '{{.Repository}}' | grep -E '(^|_|-)'$DOCKER_CONTAINER_APP'($)' )
						[ -n "$imageid" ] && docker rmi "$imageid" --force && ECHO_YELLOW "Deleting images" || ECHO_WARN_YELLOW "Image not found"
					else
						ECHO_ERROR "Docker image does not exist"
					fi

					if [ $( docker volume ls --format '{{.Name}}' | grep -E '(^|_|-)'$DOCKER_VOLUME_DB'($)' ) ];
					then
						EMPTY_LINE
						volumename=$( docker volume ls --format '{{.Name}}' | grep -E '(^|_|-)'$DOCKER_VOLUME_DB'($)' )
						[ -n "$volumename" ] && docker volume rm "$volumename" && ECHO_YELLOW "Deleting Volume" || echo "Volume not found"
					else
						ECHO_ERROR "Docker volume does not exist"
					fi

					delete_site_data
					notice_windows_host rem
					
					break
					;;
				[Nn]*) 
					unset_variables
					actions_existing_project
					;;

				*) echo "Please answer yes or no" ;;
			esac
		done
	else
		ECHO_ERROR "Site DIR does not exist: $PROJECT_ROOT_DIR"
	fi
}
