#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

unzip_project() {
	get_archived_projects

	if [[ "$DOMAIN_NAME" ]]; then
		ECHO_YELLOW "Unzipping files ..."
		mkdir -p $PROJECT_ROOT_DIR

		if [ -d $PROJECT_ROOT_DIR ]; then
			unzip -o $FILENAME -d $PROJECT_DIR

			update_file_instances
			setup_hosts_file add
			rm -rf $FILENAME
			docker_rebuild
			database_import

			ECHO_SUCCESS "Successfully restored."
		else
			ECHO_WARN_RED "Directory name doesn't exists: $PROJECT_DIR"
		fi
	else
		ECHO_WARN_RED "Archives doesn't exists"
	fi
}
