#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

env_create() {
	ENV_MAP=(
		"COMPOSE_PROJECT_NAME=$COMPOSE_PROJECT_NAME"
		"DOMAIN_NAME=$DOMAIN_NAME"
		"DOMAIN_FULL=$DOMAIN_FULL"
		"PORT=$PORT"
		# WP
		"WP_VERSION=$WP_VERSION"
		"TABLE_PREFIX=$TABLE_PREFIX"
		"WP_USER=$WP_USER"
		"WP_PASSWORD=$WP_PASSWORD"
		"PHP_VERSION=$PHP_VERSION"
		# Headless CMS
		"PORT_FRONT=$PORT_FRONT"
		# Node.js
		"MONGODB_LOCAL_PORT=$MONGODB_LOCAL_PORT"
		"MONGO_EXPRESS_PORT=$MONGO_EXPRESS_PORT"
		"NODE_VERSION=$NODE_VERSION"
		# Directus
		"DIRECTUS_VERSION=$DIRECTUS_VERSION"
		# Elasticsearch
		"ELASTIC_VERSION=$ELASTIC_VERSION"
		"ELASTIC_PORT=$ELASTIC_PORT"
		"KIBANA_PORT=$KIBANA_PORT"
		"LOGSTASH_PORT=$LOGSTASH_PORT"
	)

	for item in "${ENV_MAP[@]}"; do
		key=${item%%=*}
		value=${item#*=}

		echo "key: $key"
		echo "value: $value"

		sed_inplace "s/{$key}/'$value'/g" $PROJECT_DOCKER_DIR/.env

	done

	# Replace only first occurrence safely
	sed_inplace "s|^MYSQL_DATABASE='{MYSQL_DATABASE}'|MYSQL_DATABASE='$DB_NAME'|" "$PROJECT_DOCKER_DIR/.env"

}

env_load() {
	if [[ -f $PROJECT_DOCKER_DIR/.env ]]; then
		source $PROJECT_DOCKER_DIR/.env
	fi
}

replace_env() {
	local key=$1
	local value=$2
	local file=$3

	sed_inplace "s/{$key}/'$value'/g" "$file"
}

sed_inplace() {
	case "$(uname)" in
	Darwin)
		sed -i '' "$@"
		;;
	*)
		sed -i "$@"
		;;
	esac
}
