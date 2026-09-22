#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

env_create() {
	local env_file="${1:-$PROJECT_DOCKER_DIR/.env}"

	if [[ ! -f "$env_file" ]]; then
		return 0
	fi

	ENV_MAP=(
		"COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-}"
		"DOMAIN_NAME=${DOMAIN_NAME:-}"
		"DOMAIN_FULL=${DOMAIN_FULL:-}"
		"PORT=${PORT:-}"
		# WP
		"WP_VERSION=${WP_VERSION:-}"
		"TABLE_PREFIX=${TABLE_PREFIX:-}"
		"WP_USER=${WP_USER:-}"
		"WP_PASSWORD=${WP_PASSWORD:-}"
		"PHP_VERSION=${PHP_VERSION:-}"
		# Headless CMS
		"PORT_FRONT=${PORT_FRONT:-}"
		# Node.js
		"MONGODB_LOCAL_PORT=${MONGODB_LOCAL_PORT:-}"
		"MONGO_EXPRESS_PORT=${MONGO_EXPRESS_PORT:-}"
		"NODE_VERSION=${NODE_VERSION:-}"
		# Directus
		"DIRECTUS_VERSION=${DIRECTUS_VERSION:-}"
		"DB_NAME=${DB_NAME:-}"
		# Elasticsearch
		"ELASTIC_VERSION=${ELASTIC_VERSION:-}"
		"ELASTIC_PORT=${ELASTIC_PORT:-}"
		"KIBANA_PORT=${KIBANA_PORT:-}"
		"LOGSTASH_PORT=${LOGSTASH_PORT:-}"
	)

	for item in "${ENV_MAP[@]}"; do
		key=${item%%=*}
		value=${item#*=}
		value=${value//\\/\\\\}
		value=${value//&/\\&}
		sed_inplace "s|{$key}|${value}|g" "$env_file"
	done

	# Replace only first occurrence safely
	sed_inplace "s|^MYSQL_DATABASE='{MYSQL_DATABASE}'|MYSQL_DATABASE='$DB_NAME'|" "$env_file"
}

env_load() {
	env_load_file "${PROJECT_DOCKER_DIR}/.env"
}

env_file_value() {
	local key="${1:-}"
	local file="${2:-$PROJECT_DOCKER_DIR/.env}"
	local value

	is_safe_ident "$key" || return 1
	[[ -f "$file" ]] || return 1

	value=$(awk -F= -v k="$key" '
		index($0, k "=") == 1 {
			sub("^" k "=", "")
			gsub(/\r$/, "")
			print
			exit
		}
	' "$file")

	value="${value#"${value%%[![:space:]]*}"}"
	case "$value" in
	\'*\')
		value="${value#\'}"
		value="${value%\'}"
		;;
	\"*\")
		value="${value#\"}"
		value="${value%\"}"
		;;
	esac

	printf '%s' "$value"
}

replace_env() {
	local key=$1
	local value=$2
	local file=$3

	sed_inplace "s|{$key}|${value}|g" "$file"
}

# Load existing .env, or create placeholders. Prefer env_create for new sites.
env_file_load() {
	local ACTION=${1:-}
	get_project_dir "skip_question"

	if [[ $ACTION == 'create' ]]; then
		env_create
		[[ "yes" == "${MULTISITE:-}" ]] && wp_multisite_env
		rm -f "$PROJECT_ROOT_DIR/.env.example"
	elif [[ $ACTION == 'update' ]]; then
		sed_inplace "s|^DOMAIN_ELASTIC=.*$|DOMAIN_ELASTIC='${DOMAIN_ELASTIC:-}'|" "$PROJECT_DOCKER_DIR/.env"
		sed_inplace "s|^DOMAIN_KIBANA=.*$|DOMAIN_KIBANA='${DOMAIN_KIBANA:-}'|" "$PROJECT_DOCKER_DIR/.env"
	elif [[ -f "$PROJECT_DOCKER_DIR/.env" ]]; then
		env_load
	else
		ECHO_YELLOW ".env file not found, creating..."
		env_create
	fi
}
