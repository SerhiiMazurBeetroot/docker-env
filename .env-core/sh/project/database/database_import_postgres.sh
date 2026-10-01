#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# psql inside the database container. Names are passed as arguments, not spliced
# into a host-side bash -c script.
database_import_postgres_exec() {
	docker exec -i \
		-e "PGPASSWORD=${POSTGRES_PASSWORD:-${DB_PASSWORD:-}}" \
		"$DOCKER_CONTAINER_DB" \
		"$@"
}

database_import_postgres_psql() {
	local user="$1"
	local database="$2"
	shift 2

	database_import_postgres_exec psql -v ON_ERROR_STOP=1 -U "$user" -d "$database" "$@"
}

database_import_postgres_wait() {
	local user="$1"
	local database="$2"
	local attempts=0
	local count

	while true; do
		count=$(database_import_postgres_exec psql -U "$user" -d postgres -tAc "SELECT COUNT(*) FROM pg_stat_activity WHERE datname = '${database}' AND pid <> pg_backend_pid();" || echo 1)
		count=$(printf '%s' "$count" | tr -d '[:space:]')

		if [[ "$count" == "0" ]]; then
			return 0
		fi

		if ((attempts >= 15)); then
			ECHO_ERROR "Connections to ${database} did not close"
			return 1
		fi

		database_import_postgres_exec psql -U "$user" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${database}' AND pid <> pg_backend_pid();" || true

		ECHO_YELLOW "Waiting for active connections to ${database} to close..."
		attempts=$((attempts + 1))
		sleep 1
	done
}

database_import_postgres() {
	local name="${1:-${DB_NAME:-}}"
	local user="${2:-${DB_USER:-}}"
	local container="${DOCKER_CONTAINER_DB:-}"
	local dump="/docker-entrypoint-initdb.d/dump.sql"
	local temp_db="${name}_dump"
	local format=""

	if [[ -z "$container" ]]; then
		ECHO_ERROR "Database container is not set"
		return 1
	fi

	if [[ ! "$name" =~ ^[A-Za-z0-9_]+$ || ! "$user" =~ ^[A-Za-z0-9_]+$ ]]; then
		ECHO_ERROR "Database name or user is not safe to import"
		return 1
	fi

	if ! docker exec -i "$container" test -f "$dump"; then
		ECHO_ERROR "Dump not found in container: $dump"
		return 1
	fi

	database_import_postgres_wait "$user" "$temp_db" || return 1
	database_import_postgres_psql "$user" "$name" -c "DROP DATABASE IF EXISTS ${temp_db};" || return 1
	database_import_postgres_wait "$user" "$name" || return 1
	database_import_postgres_psql "$user" postgres -c "ALTER DATABASE ${name} RENAME TO ${temp_db};" || return 1
	database_import_postgres_psql "$user" postgres -c "CREATE DATABASE ${name};" || return 1
	database_import_postgres_psql "$user" postgres -c "ALTER DATABASE ${name} OWNER TO ${user};" || return 1

	format=$(docker exec -i "$container" pg_restore --list "$dump" 2>/dev/null | awk '/Format:/{print $NF}' || true)

	case "$format" in
	TAR)
		ECHO_INFO "Import format: TAR"
		database_import_postgres_exec pg_restore --clean --if-exists -U "$user" -F t -d "$name" "$dump" || {
			ECHO_ERROR "Import failed. Previous database was kept as ${temp_db}"
			return 1
		}
		;;
	CUSTOM)
		ECHO_INFO "Import format: CUSTOM"
		database_import_postgres_exec pg_restore --clean --if-exists -U "$user" -F c -d "$name" "$dump" || {
			ECHO_ERROR "Import failed. Previous database was kept as ${temp_db}"
			return 1
		}
		;;
	*)
		ECHO_INFO "Import format: plain SQL"
		database_import_postgres_psql "$user" "$name" -f "$dump" || {
			ECHO_ERROR "Import failed. Previous database was kept as ${temp_db}"
			return 1
		}
		;;
	esac

	database_import_postgres_psql "$user" postgres -c "DROP DATABASE IF EXISTS ${temp_db};" || true
}
