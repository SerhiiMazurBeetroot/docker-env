#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

get_php_versions() {
	QUESTION=${1:-}
	local PHP_LIST=()

	PHP_LIST=($(curl -fs 'https://www.php.net/releases/index.php?json' | jq -r '.[].supported_versions[]' | sort -Vr | uniq))

	PHP_VERSION="${PHP_LIST[1]}"

	if [[ -z "${PHP_VERSION:-}" ]]; then
		if [[ ${QUESTION:-} == "default" ]]; then
			PHP_VERSION="${PHP_LIST[1]}"
		else
			ECHO_ENTER "Enter PHP_VERSION [default '$PHP_VERSION']"

			print_list "${PHP_LIST[@]}"

			choice=$(GET_USER_INPUT "select_one_of")
			choice=${choice%.*}

			if [ -z "$choice" ]; then
				choice=-1
				PHP_VERSION="${PHP_LIST[1]}"
			else
				if (("$choice" > 0 && "$choice" <= ${#PHP_LIST[@]})); then
					PHP_VERSION="${PHP_LIST[$(($choice - 1))]}"
				else
					PHP_VERSION="${PHP_LIST[1]}"
					ECHO_WARN_RED "This version of PHP does not support"
					ECHO_GREEN "Set default version: $PHP_VERSION"
					EMPTY_LINE
				fi
			fi
		fi
	fi
}

get_latest_wp_version() {
	WP=$(curl -s 'https://api.github.com/repos/wordpress/wordpress/tags?per_page=2' | grep "name" | head -n 2 | awk '$0=$2' | grep -E '[0-9]+\.[0-9]+?' | tr -d \",)
	WP=($WP)
	WP_LATEST_VER=$(echo ${WP[0]} | grep -Eo '[0-9]+\.[0-9]+\.?[0-9]+' || echo "${WP[0]}.0")
	WP_PREV_VER=$(echo ${WP[1]} | grep -Eo '[0-9]+\.[0-9]+\.?[0-9]+' || echo "${WP[1]}.0")
}

get_nodejs_version() {
	QUESTION=${1:-}
	NODE_VERSIONS=($(curl -sL 'https://raw.githubusercontent.com/nodejs/docker-node/main/versions.json' | grep -o '"[0-9]\+": {' | cut -d'"' -f2 | sed 's/: {//'))
	NODE_LATEST_VERSION="${NODE_VERSIONS}"

	if [[ -z "${NODE_VERSION:-}" ]]; then
		if [[ ${QUESTION:-} == "default" ]]; then
			NODE_VERSION="${NODE_VERSIONS[1]}"
		else
			ECHO_ENTER "Enter NODE_VERSION [default '$NODE_LATEST_VERSION']"

			print_list "${NODE_VERSIONS[@]}"

			choice=$(GET_USER_INPUT "select_one_of")
			choice=${choice%.*}

			if [ -z "$choice" ]; then
				choice=-1
				NODE_VERSION="$NODE_LATEST_VERSION"
			else
				if (("$choice" > 0 && "$choice" <= ${#NODE_VERSIONS[@]})); then
					NODE_VERSION="${NODE_VERSIONS[$(($choice - 1))]}"
				else
					EMPTY_LINE
					NODE_VERSION="${NODE_LATEST_VERSION}"
					ECHO_GREEN "Set default version: $NODE_VERSION"
					EMPTY_LINE
				fi
			fi
		fi
	fi
}

get_directus_version() {
	QUESTION=${1:-}
	# shellcheck disable=SC2207
	local LIST=()

	LIST=($(curl -s 'https://api.github.com/repos/directus/directus/tags' | jq -r '.[].name | sub("^v"; "")' | head -n 3))

	if [[ -z "${DIRECTUS_VERSION:-}" ]]; then
		if [[ ${QUESTION:-} == "default" ]]; then
			DIRECTUS_VERSION="${LIST[1]}"
		else
			DIRECTUS_VERSION="${LIST[1]}"
			ECHO_ENTER "Enter DIRECTUS_VERSION [default '$DIRECTUS_VERSION']"

			print_list "${LIST[@]}"

			choice=$(GET_USER_INPUT "select_one_of")
			choice=${choice%.*}

			if [ -z "$choice" ]; then
				choice=-1
				DIRECTUS_VERSION="${LIST[1]}"
			else
				if (("$choice" > 0 && "$choice" <= ${#LIST[@]})); then
					DIRECTUS_VERSION="${LIST[$(($choice - 1))]}"
				else
					ECHO_WARN_RED "Invalid choice or version. Using default version: $DIRECTUS_VERSION"
					ECHO_GREEN "Set default version: $DIRECTUS_VERSION"
					EMPTY_LINE
				fi
			fi
		fi
	fi

	[[ -n "${DIRECTUS_VERSION:-}" ]] || DIRECTUS_VERSION="10.8.2"
}

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

get_nextjs_version() {
	QUESTION=${1:-}

	pkg="create-next-app"
	data=$(curl -s "https://registry.npmjs.org/$pkg")

	if [ -z "$data" ]; then
		echo "Error: no data from npm registry"
		return 1
	fi

	# all stable versions
	versions=$(echo "$data" | jq -r '.versions | keys[]' | grep -vE '-')

	# major versions
	majors=$(echo "$versions" | cut -d. -f1 | sort -Vr | uniq | head -n 3)

	LIST=()

	for major in $majors; do
		latest=$(echo "$versions" | grep -E "^${major}\." | sort -Vr | head -n 1)
		LIST+=("$latest")
	done

	DEFAULT_VERSION="${LIST[0]}"

	if [[ -z "${NEXTJS_VERSION:-}" ]]; then
		if [[ $QUESTION == "default" ]]; then
			NEXTJS_VERSION="$DEFAULT_VERSION"
		else
			ECHO_ENTER "Enter NEXTJS_VERSION [default '$DEFAULT_VERSION']"
			print_list "${LIST[@]}"

			choice=$(GET_USER_INPUT "select_one_of")
			choice=${choice%.*}

			if [ -z "$choice" ]; then
				NEXTJS_VERSION="$DEFAULT_VERSION"
			elif ((choice > 0 && choice <= ${#LIST[@]})); then
				NEXTJS_VERSION="${LIST[$((choice - 1))]}"
			else
				ECHO_WARN_RED "Invalid choice. Using default: $DEFAULT_VERSION"
				NEXTJS_VERSION="$DEFAULT_VERSION"
			fi
		fi
	fi
}
