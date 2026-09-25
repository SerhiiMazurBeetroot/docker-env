#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# instances.json:
# { "sites": [ { "port", "status", "domain_name", "domain_full",
#                "db_name", "db_type", "project_type", "port_front" } ] }

_instances_field() {
	case "$1" in
	port | status | domain_name | domain_full | db_name | db_type | project_type | port_front)
		printf '%s' "$1"
		;;
	*)
		return 1
		;;
	esac
}

instances_prepare() {
	if declare -F migrate_instances_log_to_json >/dev/null 2>&1; then
		migrate_instances_log_to_json
	fi

	mkdir -p "$DIR_DATA"
	if [[ ! -f "$FILE_INSTANCES" ]]; then
		printf '%s\n' '{"sites":[]}' >"$FILE_INSTANCES"
	fi
}

_instances_write() {
	local filter="$1"
	shift
	local tmp lock="${FILE_INSTANCES}.lock"
	local i

	instances_prepare || return 1

	for ((i = 0; i < 50; i++)); do
		if mkdir "$lock" 2>/dev/null; then
			break
		fi
		sleep 0.05
	done
	if [[ ! -d "$lock" ]]; then
		ECHO_ERROR "Could not lock $FILE_INSTANCES"
		return 1
	fi

	tmp=$(mktemp "${DIR_DATA}/instances.json.XXXXXX")
	if jq "$@" "$filter" "$FILE_INSTANCES" >"$tmp"; then
		mv "$tmp" "$FILE_INSTANCES"
		cp "$FILE_INSTANCES" "${FILE_INSTANCES}.bak" || true
		rmdir "$lock" 2>/dev/null || true
		return 0
	fi

	rm -f "$tmp"
	rmdir "$lock" 2>/dev/null || true
	ECHO_ERROR "Could not update $FILE_INSTANCES"
	return 1
}

# instances_get FIELD [VALUE] [MATCH_FIELD]
# MATCH_FIELD defaults to domain_name; VALUE defaults to $DOMAIN_NAME.
instances_get() {
	local field value match_field

	field=$(_instances_field "${1:-}") || return 1
	value="${2:-$DOMAIN_NAME}"
	match_field=$(_instances_field "${3:-domain_name}") || return 1

	instances_prepare || return 1
	[[ -f "$FILE_INSTANCES" ]] || return 1

	jq -r --arg field "$field" --arg match "$match_field" --arg val "$value" '
		first(.sites[]? | select((.[$match] | tostring) == $val) | (.[$field] | tostring)) // empty
	' "$FILE_INSTANCES"
}

instances_line() {
	local value match_field

	value="${1:-$DOMAIN_NAME}"
	match_field=$(_instances_field "${2:-domain_name}") || return 1

	instances_prepare || return 1
	[[ -f "$FILE_INSTANCES" ]] || return 1

	jq -c --arg match "$match_field" --arg val "$value" '
		first(.sites[]? | select((.[$match] | tostring) == $val)) // empty
	' "$FILE_INSTANCES"
}

instances_domains() {
	local status_filter="${1:-}"

	instances_prepare || return 0
	[[ -f "$FILE_INSTANCES" ]] || return 0

	jq -r --arg want "$status_filter" '
		.sites[]?
		| select(.domain_name != null and .domain_name != "" and .domain_name != "DOMAIN_NAME")
		| select(
			if ($want == "" or $want == "all") then
				(.status == "active" or .status == "inactive")
			else
				.status == $want
			end
		)
		| "\(.status)|\(.domain_name)"
	' "$FILE_INSTANCES"
}

instances_domain_names() {
	instances_prepare || return 0
	[[ -f "$FILE_INSTANCES" ]] || return 0

	jq -r '
		.sites[]?
		| select(.domain_name != null and .domain_name != "" and .domain_name != "DOMAIN_NAME")
		| .domain_name
	' "$FILE_INSTANCES"
}

# domain, project_type, domain_full, status — one TSV row per visible site.
instances_visible_sites() {
	instances_prepare || return 0
	[[ -f "$FILE_INSTANCES" ]] || return 0

	jq -r '
		.sites[]?
		| select(.status == "active" or .status == "inactive")
		| select(.domain_name != null and .domain_name != "" and .domain_name != "DOMAIN_NAME")
		| [.domain_name, (.project_type // ""), (.domain_full // ""), .status]
		| @tsv
	' "$FILE_INSTANCES"
}

instances_port_taken() {
	local port="$1"

	instances_prepare || return 1
	[[ -f "$FILE_INSTANCES" ]] || return 1

	jq -e --argjson p "$port" '
		any(.sites[]?; (.port | tonumber? // -1) == $p)
	' "$FILE_INSTANCES" >/dev/null
}

# Append the current session site. Status is the first argument.
instances_append() {
	local status="${1:-active}"
	local port_front="${PORT_FRONT:-0}"

	[[ -n "$port_front" ]] || port_front=0

	_instances_write '
		.sites += [{
			port: $port,
			status: $status,
			domain_name: $domain,
			domain_full: $full,
			db_name: $db,
			db_type: $dbtype,
			project_type: $type,
			port_front: $front
		}]
	' \
		--arg status "$status" \
		--arg domain "${DOMAIN_NAME:-}" \
		--arg full "${DOMAIN_FULL:-}" \
		--arg db "${DB_NAME:-}" \
		--arg dbtype "${DB_TYPE:-}" \
		--arg type "${PROJECT_TYPE:-}" \
		--argjson port "${PORT:-0}" \
		--argjson front "$port_front"
}

instances_remove() {
	local value="${1:-$DOMAIN_NAME}"

	_instances_write '
		.sites |= map(select(.domain_name != $val))
	' --arg val "$value"
}

instances_set_status() {
	local status="$1"
	local value="${2:-$DOMAIN_NAME}"

	_instances_write '
		.sites |= map(if .domain_name == $val then .status = $st else . end)
	' --arg val "$value" --arg st "$status"
}

instances_set_field() {
	local field value new_val

	field=$(_instances_field "${1:-}") || return 1
	new_val="${2:-}"
	value="${3:-$DOMAIN_NAME}"

	if [[ "$field" == "port" || "$field" == "port_front" ]]; then
		_instances_write '
			.sites |= map(if .domain_name == $val then .[$field] = $nv else . end)
		' --arg field "$field" --arg val "$value" --argjson nv "${new_val:-0}"
	else
		_instances_write '
			.sites |= map(if .domain_name == $val then .[$field] = $nv else . end)
		' --arg field "$field" --arg val "$value" --arg nv "$new_val"
	fi
}

instances_domain_for_container() {
	local container="$1"

	instances_prepare || return 1
	[[ -f "$FILE_INSTANCES" ]] || return 1

	jq -r --arg cont "$container" '
		first(.sites[]? | select(.domain_name == $cont) | .domain_name) // empty
	' "$FILE_INSTANCES"
}
