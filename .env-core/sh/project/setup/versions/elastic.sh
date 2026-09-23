#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Elastic, Logstash, Kibana
get_elastic_version() {
	QUESTION=${1:-}
	# shellcheck disable=SC2207
	LIST=($(curl -s 'https://hub.docker.com/v2/repositories/library/elasticsearch/tags/?page_size=10' | jq -r '.results[].name' | sort -Vr | head -n 3))

	if [[ -z "${ELASTIC_VERSION:-}" ]]; then
		if [[ ${QUESTION:-} == "default" ]]; then
			ELASTIC_VERSION="${LIST[1]}"
		else
			ELASTIC_VERSION="${LIST[1]}"
			ECHO_ENTER "Enter ELASTIC_VERSION [default '$ELASTIC_VERSION']"

			print_list "${LIST[@]}"

			choice=$(GET_USER_INPUT "select_one_of")
			choice=${choice%.*}

			if [ -z "$choice" ]; then
				choice=-1
				ELASTIC_VERSION="${LIST[1]}"
			else
				if (("$choice" > 0 && "$choice" <= ${#LIST[@]})); then
					ELASTIC_VERSION="${LIST[$(($choice - 1))]}"
				else
					ECHO_WARN_RED "Invalid choice or version. Using default version: $ELASTIC_VERSION"
					ECHO_GREEN "Set default version: $ELASTIC_VERSION"
					EMPTY_LINE
				fi
			fi
		fi
	fi

}
