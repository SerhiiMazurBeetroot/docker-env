#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

existing_projects_list() {
	instances_prepare || return 0
	[[ -f "$FILE_INSTANCES" ]] || return 0

	EMPTY_LINE
	jq -r '
		["PORT", "STATUS", "DOMAIN_NAME", "DOMAIN_FULL", "DB_NAME", "DB_TYPE", "PROJECT_TYPE", "PORT_FRONT"],
		(.sites[]? | [(.port | tostring), .status, .domain_name, .domain_full, .db_name, .db_type, .project_type, (.port_front | tostring)])
		| @tsv
	' "$FILE_INSTANCES"
}
