#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Keep the newest BACKUP_KEEP *.sql files in a directory. Older dumps are removed.
database_backup_rotate() {
	local dir="$1"
	local keep="${BACKUP_KEEP:-5}"
	local file
	local i=0
	local stamp

	[[ -d "$dir" ]] || return 0
	[[ "$keep" =~ ^[0-9]+$ ]] || keep=5

	while IFS= read -r file; do
		[[ -n "$file" ]] || continue
		i=$((i + 1))
		if [[ "$i" -gt "$keep" ]]; then
			rm -f "$file"
		fi
	done < <(
		find "$dir" -maxdepth 1 -type f -name '*.sql' -print | while IFS= read -r file; do
			if stamp=$(stat -f %m "$file" 2>/dev/null); then
				printf '%s %s\n' "$stamp" "$file"
			else
				printf '%s %s\n' "$(stat -c %Y "$file")" "$file"
			fi
		done | sort -nr | sed 's/^[0-9]* //'
	)
}

# Dump the running database, then copy that file outside the project tree.
database_snapshot_before_delete() {
	local dest name

	if [[ "${DB_TYPE:-0}" == "0" || -z "${DOCKER_CONTAINER_DB:-}" ]]; then
		return 0
	fi

	name=$(instances_get db_name 2>/dev/null || true)
	if [[ -n "$name" ]]; then
		DB_NAME="$name"
	fi

	if [[ -z "${DB_NAME:-}" ]]; then
		ECHO_YELLOW "No database name. Snapshot skipped."
		return 0
	fi

	if ! container_is_running "$DOCKER_CONTAINER_DB"; then
		ECHO_YELLOW "Starting containers to snapshot the database..."
		if [[ ! -f "${PROJECT_DOCKER_DIR:-}/docker-compose.yml" ]]; then
			ECHO_ERROR "Cannot snapshot: database is stopped and the compose file is missing."
			return 1
		fi
		docker_compose_runner "up -d" || return 1
	fi

	TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
	DUMP_FILE="dump-${DB_NAME}-${TIMESTAMP}.sql"
	database_create_dump || return 1

	dest="${DIR_DATA}/backups/${DOMAIN_NAME}"
	mkdir -p "$dest"
	cp "$PROJECT_DATABASE_DIR/$DUMP_FILE" "$dest/"
	database_backup_rotate "$dest"
	ECHO_SUCCESS "Snapshot saved: $dest/$DUMP_FILE"
}

database_create_dump() {
	local file partial status

	env_file_load
	get_mysql_cmd

	mkdir -p "$PROJECT_DATABASE_DIR/temp"

	file="$PROJECT_DATABASE_DIR/$DUMP_FILE"
	partial="$PROJECT_DATABASE_DIR/temp/.dump-partial.sql"
	status=0

	case "${DB_TYPE:-}" in
	"MYSQL")
		docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" sh -c "$MYSQL_DUMP_CMD -uroot $MYSQL_DATABASE" >"$partial" </dev/null || status=$?
		;;
	"POSTGRES")
		docker exec -i "$DOCKER_CONTAINER_DB" pg_dump -U "$DB_USER" -d "$DB_NAME" -F t >"$partial" </dev/null || status=$?
		;;
	*)
		rm -f "$partial"
		ECHO_ERROR "Unsupported database type: ${DB_TYPE:-}"
		return 1
		;;
	esac

	# A failed dump still creates an empty file through the redirect.
	if [[ "$status" -ne 0 || ! -s "$partial" ]]; then
		rm -f "$partial"
		ECHO_ERROR "DB dump not created"
		return 1
	fi

	mv "$partial" "$file"
	database_backup_rotate "$PROJECT_DATABASE_DIR"
	rm -rf "$PROJECT_DATABASE_DIR/temp"
	ECHO_SUCCESS "Backup done $(date +%Y'-'%m'-'%d' '%H':'%M)"
}
