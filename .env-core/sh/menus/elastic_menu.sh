#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

elastic_menu() {
	load_project_modules

	while true; do
		EMPTY_LINE
		ECHO_CYAN "===== Elastic ===="
		ECHO_YELLOW "[0] Return to the previous menu"
		ECHO_GREEN "[1] Open Kibana"
		ECHO_GREEN "[2] Cluster health"
		ECHO_GREEN "[3] Logs"

		local action
		action=$(GET_USER_INPUT "select_one_of")

		case "${action:-0}" in
		0)
			return 0
			;;
		1)
			if [[ -z "${DOMAIN_KIBANA:-}" ]]; then
				ECHO_ERROR "Kibana host is not set"
			else
				site_open_url "https://${DOMAIN_KIBANA}"
			fi
			;;
		2)
			elastic_cluster_health
			;;
		3)
			site_container_logs "${DOCKER_CONTAINER_APP:-}"
			;;
		*)
			ECHO_WARN_RED "Wrong option"
			;;
		esac
	done
}
