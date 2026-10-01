#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

database_search_replace() {
	check_domain_exists

	if [[ ${DOMAIN_EXISTS:-0} != 1 ]]; then
		ECHO_ERROR "Site not exists"
		return 1
	fi

	while true; do
		local yn
		yn=$(GET_USER_INPUT "question" "Run search-replace?")

		case "$yn" in
		[Yy]*)
			search_replace_once || true
			;;
		[Nn]*)
			return 0
			;;
		*)
			ECHO_ERROR "Please answer [y/n]"
			;;
		esac
	done
}

search_replace_once() {
	local search replace

	search=$(GET_USER_INPUT "enter" "Search term")
	replace=$(GET_USER_INPUT "enter" "Replace term")

	if [[ -z "$search" ]]; then
		ECHO_ERROR "Search term is empty"
		return 1
	fi

	ECHO_YELLOW "Running search-replace. This might take a while."

	case "${PROJECT_TYPE:-}" in
	wordpress | projects | bedrock | wordpress_nextjs)
		search_replace_wordpress "$search" "$replace"
		;;
	laravel)
		search_replace_mysql_text "$search" "$replace"
		;;
	directus | directus_nextjs)
		search_replace_postgres_text "$search" "$replace"
		;;
	elasticsearch)
		search_replace_elastic "$search" "$replace"
		;;
	*)
		ECHO_ERROR "Search-replace is not available for ${PROJECT_TYPE:-this site}"
		return 1
		;;
	esac
}

search_replace_wordpress() {
	local search="$1"
	local replace="$2"

	if ! container_is_running "${DOCKER_CONTAINER_APP:-}"; then
		ECHO_ERROR "Container not running: ${DOCKER_CONTAINER_APP:-}"
		return 1
	fi

	# Arguments stay outside the shell, so quotes in the terms are not executed.
	if docker exec -i "$DOCKER_CONTAINER_APP" \
		wp search-replace --all-tables "$search" "$replace" --allow-root; then
		ECHO_SUCCESS "Search-replace completed successfully."
	else
		ECHO_ERROR "Error occurred during search-replace operation."
		return 1
	fi
}

_sql_mysql_literal() {
	local value="$1"
	value=${value//\\/\\\\}
	value=${value//\'/\'\'}
	printf "'%s'" "$value"
}

_sql_mysql_ident() {
	local value="$1"
	value=${value//\`/\`\`}
	printf '`%s`' "$value"
}

_sql_like_pattern() {
	local value="$1"
	local escape="$2"
	value=${value//${escape}/${escape}${escape}}
	value=${value//%/${escape}%}
	value=${value//_/${escape}_}
	printf '%%%s%%' "$value"
}

search_replace_mysql_text() {
	local search="$1"
	local replace="$2"
	local columns sqlfile count=0
	local table column like_pattern

	get_db_info || return 1
	if [[ ! "${DB_NAME:-}" =~ ^[A-Za-z0-9_]+$ ]]; then
		ECHO_ERROR "Database name is not safe to update"
		return 1
	fi

	if ! container_is_running "${DOCKER_CONTAINER_DB:-}"; then
		ECHO_ERROR "Container not running: ${DOCKER_CONTAINER_DB:-}"
		return 1
	fi

	_db_shell_mysql_password
	get_mysql_cmd

	columns=$(docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" \
		"$MYSQL_CMD" -uroot --batch --skip-column-names "$DB_NAME" -e \
		"SELECT TABLE_NAME, COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND DATA_TYPE IN ('char','varchar','tinytext','text','mediumtext','longtext')") || {
		ECHO_ERROR "Could not list text columns"
		return 1
	}

	sqlfile=$(mktemp "${TMPDIR:-/tmp}/search-replace.XXXXXX")
	like_pattern=$(_sql_like_pattern "$search" $'\\')

	while IFS=$'\t' read -r table column; do
		[[ -n "$table" && -n "$column" ]] || continue
		printf 'UPDATE %s SET %s = REPLACE(%s, %s, %s) WHERE %s LIKE %s ESCAPE %s;\n' \
			"$(_sql_mysql_ident "$table")" \
			"$(_sql_mysql_ident "$column")" \
			"$(_sql_mysql_ident "$column")" \
			"$(_sql_mysql_literal "$search")" \
			"$(_sql_mysql_literal "$replace")" \
			"$(_sql_mysql_ident "$column")" \
			"$(_sql_mysql_literal "$like_pattern")" \
			"$(_sql_mysql_literal $'\\')" >>"$sqlfile"
		count=$((count + 1))
	done <<<"$columns"

	if [[ "$count" -eq 0 ]]; then
		rm -f "$sqlfile"
		ECHO_INFO "No text columns to update"
		return 0
	fi

	ECHO_INFO "Updating ${count} text columns in ${DB_NAME}"
	if docker exec -e MYSQL_PWD="${MYSQL_ROOT_PASSWORD:-}" -i "$DOCKER_CONTAINER_DB" \
		"$MYSQL_CMD" -uroot "$DB_NAME" <"$sqlfile"; then
		rm -f "$sqlfile"
		ECHO_SUCCESS "Search-replace completed successfully."
	else
		rm -f "$sqlfile"
		ECHO_ERROR "Error occurred during search-replace operation."
		return 1
	fi
}

_sql_pg_literal() {
	local value="$1"
	value=${value//\'/\'\'}
	printf "'%s'" "$value"
}

_sql_pg_ident() {
	local value="$1"
	value=${value//\"/\"\"}
	printf '"%s"' "$value"
}

_search_replace_pg_user() {
	local user=""

	env_file_load || true
	user="${DB_USER:-}"
	[[ -n "$user" ]] || user=$(env_file_value POSTGRES_USER 2>/dev/null || true)
	[[ -n "$user" ]] || user=$(env_file_value DB_USERNAME 2>/dev/null || true)
	[[ -n "$user" ]] || user="postgres"
	printf '%s' "$user"
}

search_replace_postgres_text() {
	local search="$1"
	local replace="$2"
	local user columns sqlfile count=0
	local table column like_pattern

	get_db_info || return 1
	user=$(_search_replace_pg_user)

	if [[ ! "${DB_NAME:-}" =~ ^[A-Za-z0-9_]+$ || ! "$user" =~ ^[A-Za-z0-9_]+$ ]]; then
		ECHO_ERROR "Database name or user is not safe to update"
		return 1
	fi

	if ! container_is_running "${DOCKER_CONTAINER_DB:-}"; then
		ECHO_ERROR "Container not running: ${DOCKER_CONTAINER_DB:-}"
		return 1
	fi

	columns=$(docker exec -i \
		-e "PGPASSWORD=${POSTGRES_PASSWORD:-${DB_PASSWORD:-}}" \
		"$DOCKER_CONTAINER_DB" \
		psql -U "$user" -d "$DB_NAME" -tA -F $'\t' -c \
		"SELECT c.table_name, c.column_name FROM information_schema.columns c JOIN information_schema.tables t ON t.table_schema = c.table_schema AND t.table_name = c.table_name WHERE c.table_schema = 'public' AND t.table_type = 'BASE TABLE' AND c.data_type IN ('character varying', 'character', 'text')") || {
		ECHO_ERROR "Could not list text columns"
		return 1
	}

	sqlfile=$(mktemp "${TMPDIR:-/tmp}/search-replace.XXXXXX")
	like_pattern=$(_sql_like_pattern "$search" '!')

	while IFS=$'\t' read -r table column; do
		[[ -n "$table" && -n "$column" ]] || continue
		printf 'UPDATE %s SET %s = replace(%s, %s, %s) WHERE %s LIKE %s ESCAPE %s;\n' \
			"$(_sql_pg_ident "$table")" \
			"$(_sql_pg_ident "$column")" \
			"$(_sql_pg_ident "$column")" \
			"$(_sql_pg_literal "$search")" \
			"$(_sql_pg_literal "$replace")" \
			"$(_sql_pg_ident "$column")" \
			"$(_sql_pg_literal "$like_pattern")" \
			"$(_sql_pg_literal '!')" >>"$sqlfile"
		count=$((count + 1))
	done <<<"$columns"

	if [[ "$count" -eq 0 ]]; then
		rm -f "$sqlfile"
		ECHO_INFO "No text columns to update"
		return 0
	fi

	ECHO_INFO "Updating ${count} text columns in ${DB_NAME}"
	if docker exec -i \
		-e "PGPASSWORD=${POSTGRES_PASSWORD:-${DB_PASSWORD:-}}" \
		"$DOCKER_CONTAINER_DB" \
		psql -v ON_ERROR_STOP=1 -U "$user" -d "$DB_NAME" <"$sqlfile"; then
		rm -f "$sqlfile"
		ECHO_SUCCESS "Search-replace completed successfully."
	else
		rm -f "$sqlfile"
		ECHO_ERROR "Error occurred during search-replace operation."
		return 1
	fi
}

search_replace_elastic() {
	local search="$1"
	local replace="$2"
	local url payload response

	if [[ -z "${DOMAIN_FULL:-}" ]]; then
		ECHO_ERROR "Site URL is not set"
		return 1
	fi

	if ! container_is_running "${DOCKER_CONTAINER_APP:-}"; then
		ECHO_ERROR "Container not running: ${DOCKER_CONTAINER_APP:-}"
		return 1
	fi

	if ! command -v jq >/dev/null 2>&1; then
		ECHO_ERROR "jq is required for Elastic search-replace"
		return 1
	fi

	url="https://${DOMAIN_FULL}/*/_update_by_query?conflicts=proceed&refresh=true"
	payload=$(jq -n \
		--arg search "$search" \
		--arg replace "$replace" \
		'{
			query: {
				simple_query_string: {
					query: $search,
					default_operator: "and",
					lenient: true
				}
			},
			script: {
				lang: "painless",
				params: { search: $search, replace: $replace },
				source: "for (def key : ctx._source.keySet()) { if (ctx._source[key] instanceof String) { ctx._source[key] = ctx._source[key].replace(params.search, params.replace); } }"
			}
		}')

	ECHO_INFO "$url"
	if response=$(curl -kfsS -X POST "$url" -H 'Content-Type: application/json' --data-binary "$payload"); then
		printf '%s\n' "$response"
		ECHO_SUCCESS "Search-replace completed successfully."
	else
		ECHO_ERROR "Error occurred during search-replace operation."
		return 1
	fi
}
