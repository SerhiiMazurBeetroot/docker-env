#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

database_create_dump() {
	local file partial status old

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

	for old in "$PROJECT_DATABASE_DIR"/*.sql; do
		[[ -e "$old" ]] || continue
		[[ "$old" == "$file" ]] && continue
		rm -f "$old"
	done

	rm -rf "$PROJECT_DATABASE_DIR/temp"
	ECHO_SUCCESS "Backup done $(date +%Y'-'%m'-'%d' '%H':'%M)"
}
