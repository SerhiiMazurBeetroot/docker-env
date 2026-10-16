#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

unzip_project() {
	get_archived_projects || return 1

	if [[ -n "${DOMAIN_NAME:-}" && -n "${FILENAME:-}" ]]; then
		ECHO_YELLOW "Unzipping files ..."
		mkdir -p "$PROJECT_ROOT_DIR"

		if [ -d "$PROJECT_ROOT_DIR" ]; then
			unzip -o "$FILENAME" -d "$ENV_DIR/$PROJECT_DIR"

			update_file_instances
			setup_hosts_file add
			rm -rf "$FILENAME"
			docker_rebuild
			database_import

			ECHO_SUCCESS "Successfully restored."
		else
			ECHO_WARN_RED "Directory name doesn't exists: $PROJECT_DIR"
		fi
	else
		ECHO_WARN_RED "Restore cancelled or archive could not be read."
	fi
}
