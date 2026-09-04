#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

replace_wp_instances_file_2_0() {
	# Add PORT_FRONT to head
	while read line; do
		if [[ $line == *"DOMAIN_NAME"* ]]; then
			sed -i -e "s/$line/3309 \| STATUS \| DOMAIN_NAME \| DOMAIN_FULL \| DB_NAME \| DB_TYPE \| PROJECT_TYPE \| PORT_FRONT \|/g" $FILE_INSTANCES
		fi

	done <"$FILE_INSTANCES"
}
