#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Running container names, one per line. Read once per list call (see webui_list_projects).
WEBUI_RUNNING_NAMES=""

# Max sites checked at once. Each site runs two docker compose calls.
WEBUI_LIST_JOBS=6

# _webui_list_system_json RUNNING_NAMES: nginx, dozzle and web UI rows from one docker inspect.
_webui_list_system_json() {
	local running="${1:-}"
	local webui_container="${WEBUI_CONTAINER:-nginx-webui}"
	local inspect

	# Missing containers make docker inspect fail, but it still prints the ones it found.
	inspect=$(docker inspect -f '{{.Name}}{{"\t"}}{{.State.Status}}{{"\t"}}{{if .State.Health}}{{.State.Health.Status}}{{end}}' \
		nginx-proxy nginx-dozzle "$webui_container" 2>/dev/null || true)

	jq -nc \
		--arg inspect "$inspect" \
		--arg running "$running" \
		--arg webui_container "$webui_container" \
		--arg dozzle_url "http://127.0.0.1:7007" \
		--arg webui_url "$(webui_url)" '
		([ $inspect | split("\n")[] | select(length > 0) | split("\t")
			| {key: (.[0] | ltrimstr("/")), value: {state: (.[1] // ""), health: (.[2] // "")}} ]
			| from_entries) as $info
		| [ $running | split("\n")[] | select(length > 0) ] as $up
		| def svc($id; $name; $container; $urls; $actions):
			($info[$container] // null) as $i
			| {
				id: $id,
				name: $name,
				container: $container,
				running: ($up | any(. == $container)),
				state: (if $i then ($i.state | ascii_downcase) else "missing" end),
				health: (if $i then ($i.health | ascii_downcase) else "" end),
				status: (if $i then $i.state + (if $i.health != "" then " (" + $i.health + ")" else "" end) else "" end),
				urls: $urls,
				actions: $actions
			};
		["start", "stop", "restart"] as $actions
		| [
			svc("nginx"; "Nginx"; "nginx-proxy"; []; $actions),
			svc("dozzle"; "Dozzle"; "nginx-dozzle"; [{key: "UI", url: $dozzle_url}]; $actions),
			svc("webui"; "Web UI"; $webui_container; [{key: "UI", url: $webui_url}]; [])
		]
	'
}

# _webui_list_row DOMAIN TYPE FULL STATUS: one project row as compact JSON.
# Runs in its own subshell (see webui_list_projects), so the project globals it sets stay there.
_webui_list_row() {
	local domain="${1:-}"
	local type="${2:-}"
	local full="${3:-}"
	local status="${4:-}"
	local running=false
	local url=""

	DOMAIN_NAME="$domain"
	PROJECT_TYPE="$type"
	PROJECT_ROOT_DIR=""
	PROJECT_DOCKER_DIR=""
	DOCKER_CONTAINER_APP=""
	DOMAIN_FRONT=""
	DOMAIN_ADMIN=""
	DOMAIN_DB=""
	DOMAIN_MAIL=""
	DOMAIN_KIBANA=""
	DOMAIN_LOGSTASH=""

	if get_project_dir "skip_question" >/dev/null 2>&1; then
		# Same match as container_is_running, against the names read once for the whole list.
		if [[ -n "$DOCKER_CONTAINER_APP" ]] &&
			printf '%s\n' "$WEBUI_RUNNING_NAMES" | grep -qE "(^|_|-)${DOCKER_CONTAINER_APP}($)"; then
			running=true
		fi
	fi

	[[ -n "$full" ]] && url="https://${full}"

	jq -nc \
		--arg domain "$domain" \
		--arg status "$status" \
		--arg type "$type" \
		--arg domainFull "$full" \
		--argjson running "$running" \
		--arg url "$url" \
		--argjson urls "$(webui_collect_urls)" \
		--argjson services "$(webui_collect_services)" \
		'{domain:$domain,status:$status,type:$type,domainFull:$domainFull,running:$running,url:$url,urls:$urls,services:$services}'
}

# domain, project_type, domain_full, status — one TSV row per listed site, from one jq read.
_webui_list_sites() {
	instances_prepare || return 0
	[[ -f "$FILE_INSTANCES" ]] || return 0

	jq -r '
		.sites[]?
		| select(.domain_name != null and .domain_name != "" and .domain_name != "DOMAIN_NAME")
		| [.domain_name, (.project_type // "" | tostring), (.domain_full // "" | tostring), (.status // "" | tostring)]
		| @tsv
	' "$FILE_INSTANCES"
}

webui_list_projects() {
	local domain type full status system_json tmp i n
	local pids=()

	webui_cli_boot

	WEBUI_RUNNING_NAMES=$(docker ps --format '{{.Names}}' 2>/dev/null || true)
	tmp=$(mktemp -d "${TMPDIR:-/tmp}/webui-list.XXXXXX")

	# Each site runs in the background and writes its row to its own numbered file.
	# A site whose check fails leaves an empty file and is left out, as before.
	i=0
	while IFS=$'\t' read -r domain type full status; do
		[[ -n "$domain" ]] || continue

		_webui_list_row "$domain" "$type" "$full" "$status" >"$tmp/$i" 2>/dev/null &
		pids+=("$!")
		i=$((i + 1))

		if [[ ${#pids[@]} -ge $WEBUI_LIST_JOBS ]]; then
			wait "${pids[@]}" 2>/dev/null || true
			pids=()
		fi
	done < <(_webui_list_sites)

	if [[ ${#pids[@]} -gt 0 ]]; then
		wait "${pids[@]}" 2>/dev/null || true
	fi

	system_json=$(_webui_list_system_json "$WEBUI_RUNNING_NAMES")

	# Rows are read back in catalog order.
	n=$i
	i=0
	while [[ $i -lt $n ]]; do
		[[ -s "$tmp/$i" ]] && cat "$tmp/$i"
		i=$((i + 1))
	done | jq -s --argjson system "${system_json:-[]}" '{ok:true,projects:.,system:$system}' || {
		jq -n --argjson system "${system_json:-[]}" '{ok:false,error:"Could not build project list",projects:[],system:$system}'
	}

	rm -rf "$tmp"
}

webui_list_types() {
	webui_cli_boot
	env_mode >&2
	project_catalog_emit_json
}
