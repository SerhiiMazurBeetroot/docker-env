#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# instances.log columns (pipe-delimited):
# PORT | STATUS | DOMAIN_NAME | DOMAIN_FULL | DB_NAME | DB_TYPE | PROJECT_TYPE | PORT_FRONT |

_instances_col() {
	case "$1" in
	port) echo 1 ;;
	status) echo 2 ;;
	domain_name) echo 3 ;;
	domain_full) echo 4 ;;
	db_name) echo 5 ;;
	db_type) echo 6 ;;
	project_type) echo 7 ;;
	port_front) echo 8 ;;
	*) echo 0 ;;
	esac
}

# instances_get FIELD [VALUE] [MATCH_FIELD]
# MATCH_FIELD defaults to domain_name; VALUE defaults to $DOMAIN_NAME.
instances_get() {
	local field="$1"
	local value="${2:-$DOMAIN_NAME}"
	local match_field="${3:-domain_name}"
	local col match_col

	col="$(_instances_col "$field")"
	match_col="$(_instances_col "$match_field")"
	[[ "$col" -gt 0 && "$match_col" -gt 0 && -f "$FILE_INSTANCES" ]] || return 1

	awk -F '|' -v col="$col" -v mcol="$match_col" -v val="$value" '
		function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
		NR == 1 { next }
		trim($mcol) == val { print trim($col); exit }
	' "$FILE_INSTANCES"
}

instances_line() {
	local value="${1:-$DOMAIN_NAME}"
	local match_field="${2:-domain_name}"
	local match_col

	match_col="$(_instances_col "$match_field")"
	[[ "$match_col" -gt 0 && -f "$FILE_INSTANCES" ]] || return 1

	awk -F '|' -v mcol="$match_col" -v val="$value" '
		function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
		NR == 1 { next }
		trim($mcol) == val { print $0; exit }
	' "$FILE_INSTANCES"
}

instances_domains() {
	local status_filter="${1:-}"

	[[ -f "$FILE_INSTANCES" ]] || return 0

	awk -F '|' -v want="$status_filter" '
		function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
		NR == 1 { next }
		{
			st = trim($2)
			dn = trim($3)
			if (dn == "" || dn == "DOMAIN_NAME") next
			if (want == "" || want == "all") {
				if (st == "active" || st == "inactive") print st "|" dn
			} else if (st == want) {
				print st "|" dn
			}
		}
	' "$FILE_INSTANCES"
}

instances_domain_names() {
	[[ -f "$FILE_INSTANCES" ]] || return 0

	awk -F '|' '
		function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
		NR == 1 { next }
		{
			dn = trim($3)
			if (dn != "" && dn != "DOMAIN_NAME") print dn
		}
	' "$FILE_INSTANCES"
}

instances_port_taken() {
	local port="$1"

	[[ -f "$FILE_INSTANCES" ]] || return 1

	awk -F '|' -v p="$port" '
		function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
		NR == 1 { next }
		trim($1) == p { found = 1; exit }
		END { exit found ? 0 : 1 }
	' "$FILE_INSTANCES"
}

instances_append() {
	local line="$1"

	echo "$line" >>"$FILE_INSTANCES"
	echo "$line" >>"${FILE_INSTANCES}.bak"
}

instances_remove() {
	local value="${1:-$DOMAIN_NAME}"

	[[ -f "$FILE_INSTANCES" ]] || return 0

	awk -F '|' -v val="$value" '
		function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
		NR == 1 { print; next }
		trim($3) != val { print }
	' "$FILE_INSTANCES" >"${FILE_INSTANCES}.tmp" && mv "${FILE_INSTANCES}.tmp" "$FILE_INSTANCES"
	cp "$FILE_INSTANCES" "${FILE_INSTANCES}.bak"
}

instances_set_status() {
	local status="$1"
	local value="${2:-$DOMAIN_NAME}"

	[[ -f "$FILE_INSTANCES" ]] || return 1

	awk -F '|' -v val="$value" -v st="$status" -v OFS='|' '
		function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
		NR == 1 { print; next }
		trim($3) == val { $2 = " " st " "; print; next }
		{ print }
	' "$FILE_INSTANCES" >"${FILE_INSTANCES}.tmp" && mv "${FILE_INSTANCES}.tmp" "$FILE_INSTANCES"
	cp "$FILE_INSTANCES" "${FILE_INSTANCES}.bak"
}

instances_set_field() {
	local field="$1"
	local new_val="$2"
	local value="${3:-$DOMAIN_NAME}"
	local col

	col="$(_instances_col "$field")"
	[[ "$col" -gt 0 && -f "$FILE_INSTANCES" ]] || return 1

	awk -F '|' -v val="$value" -v col="$col" -v nv="$new_val" -v OFS='|' '
		function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
		NR == 1 { print; next }
		trim($3) == val { $col = " " nv " "; print; next }
		{ print }
	' "$FILE_INSTANCES" >"${FILE_INSTANCES}.tmp" && mv "${FILE_INSTANCES}.tmp" "$FILE_INSTANCES"
	cp "$FILE_INSTANCES" "${FILE_INSTANCES}.bak"
}

instances_domain_for_container() {
	local container="$1"

	[[ -f "$FILE_INSTANCES" ]] || return 1

	awk -F '|' -v cont="$container" '
		function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
		NR == 1 { next }
		$0 ~ cont { print trim($3); exit }
	' "$FILE_INSTANCES"
}
