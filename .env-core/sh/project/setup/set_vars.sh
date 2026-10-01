#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

set_project_vars() {
	get_project_type

	PROJECT_DIR=$PROJECT_TYPE
	DOMAIN_NODOT=$(echo "$DOMAIN_NAME" | tr . _)
	PROJECT_ROOT_DIR="$ENV_DIR"/"$PROJECT_DIR"/"$DOMAIN_FULL"
	PROJECT_ARCHIVE_DIR=$PROJECT_DIR"_""$DOMAIN_FULL"

	# Set default variables
	DOMAIN_NAME_DEFAULT="dev.$DOMAIN_NAME.local"
	DOMAIN_DB=""
	DOCKER_VOLUME_DB="$DOMAIN_NAME"_db_data
	DOCKER_CONTAINER_DB="$DOMAIN_NAME-mysql"
	PROJECT_DOCKER_DIR=$(project_compose_dir "${PROJECT_TYPE:-}" || printf '%s' "$PROJECT_ROOT_DIR/docker")
	PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/database
	DB_TYPE="0"
	DB_NAME="db"
	DOMAIN_FRONT=""
	DOMAIN_ADMIN=""
	DOMAIN_MAIL=""
	HOST_EXTRA=""

	PROJECT_BACKEND_DIR=$PROJECT_ROOT_DIR/backend
	PROJECT_FRONTEND_DIR=$PROJECT_ROOT_DIR/frontend

	if [[ -z "$PORT_FRONT" ]]; then
		PORT_FRONT=0
	fi

	get_compose_project_name

	case ${PROJECT_TYPE:-} in
	"wordpress" | "projects")
		DB_TYPE="MYSQL"
		DOMAIN_ADMIN="$DOMAIN_FULL/wp-admin"
		PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/wp-database
		PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/wp-content
		DOMAIN_DB="$DOMAIN_FULL.phpmyadmin"
		DOMAIN_MAIL="$DOMAIN_FULL.mail"
		HOST_EXTRA="$DOMAIN_DB $DOMAIN_MAIL"
		;;
	"bedrock")
		DB_TYPE="MYSQL"
		DOMAIN_ADMIN="$DOMAIN_FULL/wp/wp-admin"
		PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/app/web/app
		DOMAIN_DB="$DOMAIN_FULL.phpmyadmin"
		DOMAIN_MAIL="$DOMAIN_FULL.mail"
		HOST_EXTRA="$DOMAIN_DB $DOMAIN_MAIL"
		;;
	"php")
		PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/app
		;;
	"wordpress_nextjs")
		DB_TYPE="MYSQL"
		PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/database
		PROJECT_WP_CONTENT_DIR=$PROJECT_ROOT_DIR/wp-content
		DOCKER_CONTAINER_DB="$DOMAIN_NAME-mysql"
		DOMAIN_ADMIN="${DOMAIN_FULL}.wp"
		DOMAIN_DB="$DOMAIN_FULL.phpmyadmin"
		DOMAIN_MAIL="$DOMAIN_FULL.mail"
		HOST_EXTRA="$DOMAIN_ADMIN $DOMAIN_DB $DOMAIN_MAIL"
		;;
	"nodejs")
		DB_TYPE="MONGO"
		PROJECT_DIR="nodejs"
		DOCKER_CONTAINER_DB="$DOMAIN_NAME-mongo"
		;;
	"nodejs_api")
		DB_TYPE="0"
		DOCKER_VOLUME_DB=""
		DOCKER_CONTAINER_DB=""
		;;
	"nextjs")
		;;
	"directus")
		DB_TYPE="POSTGRES"
		DB_NAME="directus"
		DOMAIN_DB="$DOMAIN_FULL.pgadmin"
		DOCKER_CONTAINER_DB="$DOMAIN_NAME-postgres"
		HOST_EXTRA="$DOMAIN_DB"
		;;
	"directus_nextjs")
		DB_TYPE="POSTGRES"
		DB_NAME="directus"
		DOMAIN_ADMIN="${DOMAIN_FULL}.directus"
		DOMAIN_DB="${DOMAIN_FULL}.pgadmin"
		DOCKER_CONTAINER_DB="${DOMAIN_NAME}-postgres"
		HOST_EXTRA="$DOMAIN_ADMIN $DOMAIN_DB"
		;;
	"elasticsearch")
		DOMAIN_LOGSTASH="$DOMAIN_FULL.logstash"
		DOMAIN_KIBANA="$DOMAIN_FULL.kibana"
		HOST_EXTRA="$DOMAIN_LOGSTASH $DOMAIN_KIBANA"
		;;
	"laravel")
		DB_TYPE="MYSQL"
		PROJECT_DATABASE_DIR=$PROJECT_ROOT_DIR/database
		DOMAIN_ADMIN="$DOMAIN_FULL/login"
		DOMAIN_DB="$DOMAIN_FULL.phpmyadmin"
		DOMAIN_MAIL="$DOMAIN_FULL.mail"
		HOST_EXTRA="$DOMAIN_DB $DOMAIN_MAIL"
		;;
	*)
		echo "Unknown PROJECT_TYPE: $PROJECT_TYPE"
		return 1
		;;
	esac

	DOCKER_CONTAINER_APP=$(project_container_name) || return 1
}
