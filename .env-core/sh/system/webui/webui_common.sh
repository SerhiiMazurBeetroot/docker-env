#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

webui_url() {
	printf 'http://%s:%s' "${WEBUI_HOST:-127.0.0.1}" "${WEBUI_PORT:-7777}"
}

webui_cli_boot() {
	load_project_modules
	load_system_modules
	docker_compose_version
	docker_nginx_container
}

webui_select_project() {
	local domain="${1:-}"

	if [[ -z "$domain" ]]; then
		ECHO_ERROR "Domain is required"
		return 1
	fi

	if ! is_safe_hostname "$domain"; then
		ECHO_ERROR "Invalid domain name"
		return 1
	fi

	if [[ -z "$(instances_line "$domain")" ]]; then
		ECHO_ERROR "Unknown project: $domain"
		return 1
	fi

	DOMAIN_NAME="$domain"
	PROJECT_TYPE=""
	PROJECT_ROOT_DIR=""
	PROJECT_DOCKER_DIR=""
	DOCKER_CONTAINER_APP=""
	DOCKER_VOLUME_DB=""

	get_project_dir "skip_question" || return 1
	docker_require_project_context "======== Web UI ========" || return 1
}

webui_collect_urls() {
	local key host url
	local pairs=""
	local keys=(DOMAIN_FULL DOMAIN_FRONT DOMAIN_ADMIN DOMAIN_DB DOMAIN_MAIL DOMAIN_KIBANA DOMAIN_LOGSTASH)

	for key in "${keys[@]}"; do
		host="${!key:-}"
		[[ -n "$host" ]] || continue

		case "$host" in
		http://* | https://*)
			url="$host"
			;;
		*)
			url="https://${host}"
			;;
		esac

		pairs+="${key}"$'\t'"${url}"$'\n'
	done

	# One jq call for all keys. Each key/url pair is one tab-separated line.
	jq -nc --arg pairs "$pairs" '
		[ $pairs | split("\n")[] | select(length > 0) | split("\t") | {key: .[0], url: (.[1:] | join("\t"))} ]
	'
}

webui_collect_services() {
	local dir="${PROJECT_DOCKER_DIR:-}"
	local names=""
	local ps_raw=""

	if [[ -z "$dir" || ! -f "$dir/docker-compose.yml" ]]; then
		printf '[]'
		return 0
	fi

	names=$(docker_compose_output "config --services" "$dir" 2>/dev/null || true)
	ps_raw=$(docker_compose_output "ps -a --format json" "$dir" 2>/dev/null || true)

	# Compose prints either one JSON array or one object per line, depending on its version.
	# Services from `config --services` keep their order; with no names, every ps row is listed.
	jq -nc --arg names "$names" --arg ps "$ps_raw" '
		def health_of:
			if ((.Health // "") != "") then (.Health | ascii_downcase)
			elif ((.Status // "") | test("\\(unhealthy\\)"; "i")) then "unhealthy"
			elif ((.Status // "") | test("health: starting"; "i")) then "starting"
			elif ((.Status // "") | test("\\(healthy\\)"; "i")) then "healthy"
			else ""
			end;

		(try (
			[ $ps | split("\n")[] | select(test("\\S")) | fromjson ]
			| if length == 1 and (.[0] | type) == "array" then .[0] else . end
			| map({
				service: (.Service // .Name // ""),
				name: (.Name // .Service // ""),
				state: ((.State // "") | ascii_downcase),
				status: (.Status // ""),
				health: health_of
			})
		) catch []) as $acc
		| [ $names | split("\n")[] | gsub("^[ \t\r]+|[ \t\r]+$"; "") | select(length > 0) ] as $svcs
		| if ($svcs | length) == 0 then
			[ $acc[] | select(.service != "") | {
				service: .service,
				name: .name,
				state: .state,
				status: .status,
				health: (.health // ""),
				running: (.state == "running")
			}]
		else
			$svcs | map(. as $svc |
				($acc | map(select(.service == $svc or .name == $svc)) | .[0] // {}) as $hit |
				{
					service: $svc,
					name: ($hit.name // $svc),
					state: ($hit.state // "missing"),
					status: ($hit.status // ""),
					health: ($hit.health // ""),
					running: (($hit.state // "") == "running")
				}
			)
		end
	'
}

webui_emit_urls() {
	notice_project_urls "preview"
	printf 'WEBUI_URLS_JSON:%s\n' "$(webui_collect_urls)"
}

webui_service_running() {
	docker ps --format '{{.Names}}' 2>/dev/null | grep -qE "^${1}$"
}
