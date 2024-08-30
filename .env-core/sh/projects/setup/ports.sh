#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

get_unique_port() {
    # GET PORT [ count port from 3309 ]
    PORT=3309
    while true; do
        port_exist=$(awk '/'"$PORT"'/{print $1}' "$FILE_INSTANCES" | head -n 2 | tail -n 1)

        if [[ ! "$port_exist" ]]; then
            break
        fi
        ((PORT++))
    done
}

get_all_ports() {
    get_unique_port

    # [ count port from 5510 ]
    PORT_FRONT=$(($PORT + 1700))

    # [ count port from 9210 ]
    ELASTIC_PORT=$(($PORT + 5900))

    # [ count port from 5610 ]
    KIBANA_PORT=$(($PORT + 2300))

    # [ count port from 9610 ]
    LOGSTASH_PORT=$(($PORT + 6300))

    # [ count port from 8010 ]
    MAIL_PORT=$(($PORT + 4700))
}
