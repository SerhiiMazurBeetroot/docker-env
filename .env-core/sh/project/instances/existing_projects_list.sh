#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

existing_projects_list() {
	EMPTY_LINE
	awk 'NR==FNR{for(i=1;i<=NF;i++) 
        max[i] = length($i) > max[i] ? length($i) : max[i]; next} 
    { for(i=1;i<=NF;i++) printf "%-"max[i]"s  ", $i; printf "\n"}' "$FILE_INSTANCES" "$FILE_INSTANCES"
}
