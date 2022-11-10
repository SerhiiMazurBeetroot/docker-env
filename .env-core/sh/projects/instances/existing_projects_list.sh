#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

existing_projects_list() {
    EMPTY_LINE
    awk 'NR==FNR{for(i=1;i<=NF;i++) 
        max[i] = length($i) > max[i] ? length($i) : max[i]; next} 
    { for(i=1;i<=NF;i++) printf "%-"max[i]"s  ", $i; printf "\n"}' "$FILE_INSTANCES" "$FILE_INSTANCES"
}
