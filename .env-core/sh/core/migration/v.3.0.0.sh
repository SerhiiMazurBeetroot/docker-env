#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Convert the pipe-delimited instances.log into instances.json.
# Idempotent: a later run keeps an existing non-empty JSON file and
# moves a leftover log aside. An empty JSON file plus a real log is
# converted, so a startup that created {"sites":[]} first does not win.
migrate_instances_log_to_json() {
	local log="$FILE_INSTANCES_LOG"
	local json="$FILE_INSTANCES"
	local tmp count

	mkdir -p "$DIR_DATA"

	if [[ ! -f "$log" ]]; then
		if [[ ! -f "$json" ]]; then
			printf '%s\n' '{"sites":[]}' >"$json"
		fi
		return 0
	fi

	if [[ -f "$json" ]]; then
		count=$(jq -r '(.sites // []) | length' "$json" 2>/dev/null || echo 0)
		if [[ "$count" != "0" ]]; then
			mv "$log" "${log}.bak"
			return 0
		fi
	fi

	ECHO_YELLOW "Migrating instances.log to instances.json"

	tmp=$(mktemp "${DIR_DATA}/instances.json.XXXXXX")
	if ! jq -R -s '
		def trim: gsub("^[[:space:]]+|[[:space:]]+$"; "");
		split("\n")
		| map(select(length > 0))
		| map(split("|") | map(trim))
		| map(select(length >= 3))
		| map(select(.[2] != "" and .[2] != "DOMAIN_NAME" and .[1] != "STATUS"))
		| map({
			port: ((.[0] // "0") | tonumber? // 0),
			status: (.[1] // ""),
			domain_name: .[2],
			domain_full: (.[3] // ""),
			db_name: (.[4] // ""),
			db_type: (.[5] // ""),
			project_type: (.[6] // ""),
			port_front: ((.[7] // "0") | tonumber? // 0)
		})
		| {sites: .}
	' "$log" >"$tmp"; then
		rm -f "$tmp"
		ECHO_ERROR "Could not convert instances.log"
		return 1
	fi

	mv "$tmp" "$json"
	mv "$log" "${log}.bak"
	ECHO_SUCCESS "Sites are now in instances.json (previous file: instances.log.bak)"
}
