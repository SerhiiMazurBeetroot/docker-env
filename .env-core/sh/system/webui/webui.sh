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
	local urls='[]'
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

		urls=$(jq -nc --argjson acc "$urls" --arg key "$key" --arg url "$url" \
			'$acc + [{key:$key,url:$url}]')
	done

	printf '%s' "$urls"
}

webui_collect_services() {
	local dir="${PROJECT_DOCKER_DIR:-}"
	local names=""
	local ps_raw=""
	local ps_json="[]"

	if [[ -z "$dir" || ! -f "$dir/docker-compose.yml" ]]; then
		printf '[]'
		return 0
	fi

	names=$(docker_compose_output "config --services" "$dir" 2>/dev/null || true)
	ps_raw=$(docker_compose_output "ps -a --format json" "$dir" 2>/dev/null || true)

	if [[ -n "$ps_raw" ]]; then
		ps_json=$(printf '%s\n' "$ps_raw" | jq -s '
			if length == 1 and (.[0] | type) == "array" then .[0] else . end
			| map({
				service: (.Service // .Name // ""),
				name: (.Name // .Service // ""),
				state: ((.State // "") | ascii_downcase),
				status: (.Status // ""),
				health: (
					if ((.Health // "") != "") then (.Health | ascii_downcase)
					elif ((.Status // "") | test("\\(unhealthy\\)"; "i")) then "unhealthy"
					elif ((.Status // "") | test("health: starting"; "i")) then "starting"
					elif ((.Status // "") | test("\\(healthy\\)"; "i")) then "healthy"
					else ""
					end
				)
			})
		' 2>/dev/null || echo '[]')
	fi

	if [[ -z "${names//[$'\t\r\n ']/}" ]]; then
		jq -nc --argjson acc "$ps_json" '
			[ $acc[] | select(.service != "") | {
				service: .service,
				name: .name,
				state: .state,
				status: .status,
				health: (.health // ""),
				running: (.state == "running")
			}]
		'
		return 0
	fi

	printf '%s\n' "$names" | jq -R -s --argjson acc "$ps_json" '
		split("\n")
		| map(select(length > 0))
		| map(. as $svc |
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
	'
}

webui_emit_urls() {
	notice_project_urls "preview"
	printf 'WEBUI_URLS_JSON:%s\n' "$(webui_collect_urls)"
}

webui_service_running() {
	docker ps --format '{{.Names}}' 2>/dev/null | grep -qE "^${1}$"
}

webui_system_service() {
	local id="${1:-}"
	local name="${2:-}"
	local container="${3:-}"
	local urls="${4:-[]}"
	local actions="${5:-[]}"
	local running=false
	local state="missing"
	local health=""
	local status=""

	if webui_service_running "$container"; then
		running=true
	fi

	if docker inspect "$container" >/dev/null 2>&1; then
		state=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null | tr '[:upper:]' '[:lower:]')
		health=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$container" 2>/dev/null | tr '[:upper:]' '[:lower:]')
		status=$(docker inspect -f '{{.State.Status}}{{if .State.Health}} ({{.State.Health.Status}}){{end}}' "$container" 2>/dev/null)
	fi

	jq -nc \
		--arg id "$id" \
		--arg name "$name" \
		--arg container "$container" \
		--arg state "$state" \
		--arg health "$health" \
		--arg status "$status" \
		--argjson running "$running" \
		--argjson urls "$urls" \
		--argjson actions "$actions" \
		'{id:$id,name:$name,container:$container,running:$running,state:$state,health:$health,status:$status,urls:$urls,actions:$actions}'
}

webui_list_system() {
	local http="http://127.0.0.1:8080"
	local https="https://127.0.0.1"
	local dozzle="http://127.0.0.1:7007"
	local webui
	local actions
	webui=$(webui_url)
	actions='["start","stop","restart"]'

	jq -nc \
		--argjson nginx "$(webui_system_service "nginx" "Nginx" "nginx-proxy" "$(jq -nc --arg http "$http" --arg https "$https" '[{key:"HTTP",url:$http},{key:"HTTPS",url:$https}]')" "$actions")" \
		--argjson dozzle "$(webui_system_service "dozzle" "Dozzle" "nginx-dozzle" "$(jq -nc --arg url "$dozzle" '[{key:"UI",url:$url}]')" "$actions")" \
		--argjson webui "$(webui_system_service "webui" "Web UI" "${WEBUI_CONTAINER:-nginx-webui}" "$(jq -nc --arg url "$webui" '[{key:"UI",url:$url}]')" "[]")" \
		'[$nginx,$dozzle,$webui]'
}

webui_list_payload() {
	local system_json
	system_json=$(webui_list_system)

	if [[ $# -eq 0 ]]; then
		jq -n --argjson system "$system_json" '{ok:true,projects:[],system:$system}'
		return 0
	fi

	printf '%s\n' "$@" | jq -s --argjson system "$system_json" '{ok:true,projects:.,system:$system}' || {
		jq -n --argjson system "${system_json:-[]}" '{ok:false,error:"Could not build project list",projects:[],system:$system}'
	}
}

webui_list_projects() {
	local domain status type full running url row
	local rows=()

	webui_cli_boot

	while IFS= read -r domain; do
		[[ -n "$domain" ]] || continue

		status=$(instances_get status "$domain")
		type=$(instances_get project_type "$domain")
		full=$(instances_get domain_full "$domain")
		running=false

		DOMAIN_NAME="$domain"
		PROJECT_TYPE="${type:-}"
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
			if container_is_running; then
				running=true
			fi
		fi

		url=""
		[[ -n "$full" ]] && url="https://${full}"

		row=$(jq -nc \
			--arg domain "$domain" \
			--arg status "${status:-}" \
			--arg type "${type:-}" \
			--arg domainFull "${full:-}" \
			--argjson running "$running" \
			--arg url "$url" \
			--argjson urls "$(webui_collect_urls)" \
			--argjson services "$(webui_collect_services)" \
			'{domain:$domain,status:$status,type:$type,domainFull:$domainFull,running:$running,url:$url,urls:$urls,services:$services}')
		rows+=("$row")
	done < <(instances_domain_names)

	webui_list_payload "${rows[@]}"
}

webui_start_project() {
	webui_cli_boot
	webui_select_project "${1:-}" || return 1
	docker_start_project || return 1
	webui_emit_urls
}

webui_bulk_scope_type() {
	local scope="${1:-}"

	case "$scope" in
	"" | all | running | stopped)
		printf ''
		;;
	*)
		printf '%s' "$scope"
		;;
	esac
}

webui_start_all() {
	local type_filter="${1:-}"
	local domain
	local failed=0

	webui_cli_boot
	ECHO_YELLOW "Starting projects${type_filter:+ ($type_filter)}..."

	# fd 3: start runs docker exec -i (permissions) and must not eat this list.
	while IFS= read -r domain <&3; do
		[[ -n "$domain" ]] || continue
		DOMAIN_NAME="$domain"
		reset_session_var PROJECT_TYPE
		reset_session_var PROJECT_DOCKER_DIR
		reset_session_var PROJECT_ROOT_DIR
		reset_session_var DOCKER_CONTAINER_APP

		get_project_dir "skip_question" || {
			unset_variables
			continue
		}

		if [[ -n "$type_filter" && "${PROJECT_TYPE:-}" != "$type_filter" ]]; then
			unset_variables
			continue
		fi

		if container_is_running; then
			ECHO_YELLOW "Already running [${DOMAIN_NAME}]"
			unset_variables
			continue
		fi

		ECHO_YELLOW "Starting [${DOMAIN_NAME}]"
		if docker_start_project; then
			ECHO_SUCCESS "Started [${DOMAIN_NAME}]"
		else
			ECHO_ERROR "Failed to start [${DOMAIN_NAME}]"
			failed=1
		fi
		unset_variables
	done 3< <(instances_domain_names)

	docker_nginx_restart || true
	return "$failed"
}

webui_bulk_projects() {
	local action="${1:-}"
	local scope="${2:-}"
	local type_filter

	webui_cli_boot
	type_filter="$(webui_bulk_scope_type "$scope")"

	case "$action" in
	stop)
		docker_stop_all "$type_filter"
		;;
	start)
		webui_start_all "$type_filter"
		;;
	*)
		ECHO_ERROR "Unknown bulk action: ${action}"
		return 1
		;;
	esac
}

webui_hosts_path() {
	if [[ -e /host-etc-hosts ]]; then
		printf '%s' /host-etc-hosts
		return 0
	fi
	if [[ -e /.dockerenv ]]; then
		printf ''
		return 1
	fi
	printf '%s' /etc/hosts
}

webui_hosts_rewrite() {
	local file="$1"
	local action="$2"
	local site="$3"
	shift 3
	local extras=("$@")
	local tmp extra_csv

	if [[ ! -f "$file" ]]; then
		ECHO_ERROR "Hosts file not found: $file"
		return 1
	fi

	if [[ ! -w "$file" ]]; then
		ECHO_ERROR "Hosts file is not writable from Web UI ($file)."
		ECHO_YELLOW "Mount /etc/hosts at /host-etc-hosts on the webui container, or run setup from the CLI."
		return 1
	fi

	extra_csv=$(IFS=,; printf '%s' "${extras[*]}")
	tmp=$(mktemp)
	awk -v action="$action" -v site="$site" -v extra_csv="$extra_csv" '
		BEGIN { n = split(extra_csv, extras, ","); changed = 0 }
		{
			line = $0
			sub(/#.*/, "", line)
			if (line ~ /^[[:space:]]*$/) { print $0; next }
			found = 0
			for (i = 2; i <= NF; i++) if ($i == site) found = 1
			if (!found) { print $0; next }
			out = $1
			for (i = 2; i <= NF; i++) {
				tok = $i
				if (tok ~ /^#/) break
				skip = 0
				if (action == "rem") {
					for (j = 1; j <= n; j++) if (tok == extras[j]) skip = 1
				}
				if (skip) continue
				out = out " " tok
			}
			if (action == "add") {
				for (j = 1; j <= n; j++) {
					if (extras[j] == "") continue
					has = 0
					split(out, of, " ")
					for (k in of) if (of[k] == extras[j]) has = 1
					if (!has) out = out " " extras[j]
				}
			}
			print out
			changed = 1
			next
		}
		END {
			if (action == "add" && changed == 0) {
				line = "127.0.0.1 " site
				for (j = 1; j <= n; j++) if (extras[j] != "") line = line " " extras[j]
				print line
			}
		}
	' "$file" >"$tmp" || {
		rm -f "$tmp"
		return 1
	}

	cat "$tmp" >"$file" || {
		rm -f "$tmp"
		ECHO_ERROR "Failed to write $file"
		return 1
	}
	rm -f "$tmp"
	return 0
}

webui_hosts_extras() {
	local action="${1:-}"
	local domain="${2:-}"
	local file
	local extras=()

	webui_cli_boot
	webui_select_project "$domain" || return 1

	case "$action" in
	add | rem) ;;
	*)
		ECHO_ERROR "Unknown hosts action: ${action}"
		return 1
		;;
	esac

	file=$(webui_hosts_path) || true
	if [[ -z "$file" ]]; then
		ECHO_ERROR "Host /etc/hosts is not mounted at /host-etc-hosts."
		ECHO_YELLOW "Recreate the Web UI container so the new volume is attached."
		return 1
	fi
	# shellcheck disable=SC2206
	extras=(${HOST_EXTRA:-})

	if [[ ${#extras[@]} -eq 0 ]]; then
		ECHO_YELLOW "No extra hosts for ${PROJECT_TYPE:-this project} (phpMyAdmin, Kibana, …)"
		return 0
	fi

	ECHO_YELLOW "${action} extras for ${DOMAIN_FULL} in ${file}"
	ECHO_KEY_VALUE "Extras" "${extras[*]}"
	webui_hosts_rewrite "$file" "$action" "$DOMAIN_FULL" "${extras[@]}" || return 1
	ECHO_SUCCESS "Updated hosts for ${DOMAIN_FULL}"
	grep -n -- "$DOMAIN_FULL" "$file" || true
}

webui_stop_project() {
	webui_cli_boot
	webui_select_project "${1:-}" || return 1
	docker_stop
}

webui_restart_project() {
	webui_cli_boot
	webui_select_project "${1:-}" || return 1
	docker_restart || return 1
	webui_emit_urls
}

webui_rebuild_project() {
	webui_cli_boot
	webui_select_project "${1:-}" || return 1
	docker_rebuild || return 1
	docker_restart || true
	webui_emit_urls
}

webui_server_pid() {
	if [[ -f "${FILE_WEBUI_PID:-}" ]]; then
		tr -d '[:space:]' <"$FILE_WEBUI_PID"
	fi
}

webui_stop_host_process() {
	local pid comm
	pid=$(webui_server_pid)

	if [[ -z "$pid" ]]; then
		[[ -n "${FILE_WEBUI_PID:-}" && -f "$FILE_WEBUI_PID" ]] && rm -f "$FILE_WEBUI_PID"
		return 0
	fi

	# Stale pid files can reuse the current CLI pid and would kill the menu.
	if [[ "$pid" == "$$" || "$pid" == "${PPID:-}" ]]; then
		rm -f "$FILE_WEBUI_PID"
		return 0
	fi

	if kill -0 "$pid" 2>/dev/null; then
		comm=$(ps -p "$pid" -o comm= 2>/dev/null | tr -d ' ')
		if [[ "$comm" != "node" && "$comm" != "nodejs" ]]; then
			rm -f "$FILE_WEBUI_PID"
			return 0
		fi
		kill "$pid" 2>/dev/null || true
		sleep 0.2
		kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null || true
	fi
	[[ -n "${FILE_WEBUI_PID:-}" && -f "$FILE_WEBUI_PID" ]] && rm -f "$FILE_WEBUI_PID"
}

webui_server_is_running() {
	docker ps --format '{{.Names}}' 2>/dev/null | grep -qE "^${WEBUI_CONTAINER:-nginx-webui}$"
}

webui_is_dev() {
	docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "${WEBUI_CONTAINER:-nginx-webui}" 2>/dev/null \
		| grep -qx 'WEBUI_DEV=1'
}

webui_status_label() {
	if webui_server_is_running; then
		if webui_is_dev; then
			printf 'running %s (dev)' "$(webui_url)"
		else
			printf 'running %s' "$(webui_url)"
		fi
	else
		printf 'stopped'
	fi
}

webui_compose_webui() {
	local files="${1:-}"
	local args="${2:-}"

	if [[ -z "${DIR_NGINX:-}" || ! -f "${DIR_NGINX}/docker-compose.yml" ]]; then
		ECHO_ERROR "Nginx compose directory not found: ${DIR_NGINX:-}"
		return 1
	fi

	if [[ -z "${ENV_DIR:-}" ]]; then
		ECHO_ERROR "ENV_DIR is not set"
		return 1
	fi

	# shellcheck disable=SC2086
	(
		docker_compose_unset_interpolation_env
		$DOCKER_COMPOSE_CMD --project-directory "$DIR_NGINX" $files $args
	)
}

webui_open_browser() {
	local url
	url=$(webui_url)

	if [[ "${OSTYPE:-}" == "darwin" ]]; then
		open "$url" >/dev/null 2>&1 || true
	elif command -v xdg-open >/dev/null 2>&1; then
		xdg-open "$url" >/dev/null 2>&1 || true
	fi
}

webui_server_start() {
	if webui_server_is_running; then
		webui_stop_host_process
		ECHO_ATTENTION "Web UI already running at $(webui_url)"
		return 0
	fi

	webui_stop_host_process

	docker_nginx_container
	docker_nginx_env

	if [[ ! -d "${DIR_NGINX:-}" || ! -f "${DIR_NGINX}/docker-compose.yml" ]]; then
		ECHO_ERROR "Nginx compose directory not found: ${DIR_NGINX:-}"
		return 1
	fi

	if [[ -z "${ENV_DIR:-}" ]]; then
		ECHO_ERROR "ENV_DIR is not set"
		return 1
	fi

	if [[ "${NGINX_EXISTS:-0}" -eq 0 ]]; then
		ECHO_YELLOW "Starting Nginx stack (Web UI starts with it)"
		docker_nginx_start || return 1
	else
		docker_nginx_ensure_webui || return 1
	fi

	sleep 0.6

	if ! webui_server_is_running; then
		ECHO_ERROR "Web UI container failed to start (${WEBUI_CONTAINER:-nginx-webui})"
		return 1
	fi

	ECHO_SUCCESS "Web UI started at $(webui_url)"
}

webui_server_stop() {
	webui_stop_host_process

	if ! webui_server_is_running; then
		ECHO_ERROR "Web UI is not running"
		return 1
	fi

	docker stop "${WEBUI_CONTAINER:-nginx-webui}" >/dev/null || return 1
	ECHO_SUCCESS "Web UI stopped"
}

webui_server_rebuild() {
	webui_stop_host_process
	docker_nginx_container
	docker_nginx_env

	if [[ ! -d "${DIR_NGINX:-}" || ! -f "${DIR_NGINX}/docker-compose.yml" ]]; then
		ECHO_ERROR "Nginx compose directory not found: ${DIR_NGINX:-}"
		return 1
	fi

	if [[ -z "${ENV_DIR:-}" ]]; then
		ECHO_ERROR "ENV_DIR is not set"
		return 1
	fi

	ECHO_YELLOW "Rebuilding Web UI image (production)"
	webui_compose_webui \
		"-f ${DIR_NGINX}/docker-compose.yml" \
		"up -d --build --force-recreate --no-deps webui" || return 1

	sleep 0.6

	if ! webui_server_is_running; then
		ECHO_ERROR "Web UI container failed to start (${WEBUI_CONTAINER:-nginx-webui})"
		return 1
	fi

	ECHO_SUCCESS "Web UI rebuilt at $(webui_url)"
}

webui_server_develop() {
	webui_stop_host_process
	docker_nginx_container
	docker_nginx_env

	if [[ ! -f "${DIR_NGINX}/docker-compose.webui-dev.yml" ]]; then
		ECHO_ERROR "Develop compose file not found: ${DIR_NGINX}/docker-compose.webui-dev.yml"
		return 1
	fi

	ECHO_YELLOW "Starting Web UI develop image (next dev, source mounted)"
	webui_compose_webui \
		"-f ${DIR_NGINX}/docker-compose.yml -f ${DIR_NGINX}/docker-compose.webui-dev.yml" \
		"up -d --build --force-recreate --no-deps webui" || return 1

	sleep 1.2

	if ! webui_server_is_running; then
		ECHO_ERROR "Web UI develop container failed to start (${WEBUI_CONTAINER:-nginx-webui})"
		return 1
	fi

	ECHO_SUCCESS "Web UI develop at $(webui_url) — edit .env-core/webui, no rebuild"
}

webui_nginx_stop() {
	docker_nginx_container

	if [[ "${NGINX_EXISTS:-0}" -ne 1 ]]; then
		ECHO_ERROR "Nginx container not running"
		return 1
	fi

	# Do not compose down: that would also stop Web UI and Dozzle.
	docker stop nginx-proxy >/dev/null || return 1
	ECHO_SUCCESS "Nginx proxy stopped (Web UI left running)"
}

webui_dozzle_start() {
	docker_nginx_env
	docker_compose_runner "up -d dozzle" "$DIR_NGINX" || return 1
	ECHO_SUCCESS "Dozzle started"
}

webui_dozzle_stop() {
	if ! webui_service_running "nginx-dozzle"; then
		ECHO_ERROR "Dozzle is not running"
		return 1
	fi

	docker stop nginx-dozzle >/dev/null || return 1
	ECHO_SUCCESS "Dozzle stopped"
}

webui_dozzle_restart() {
	if ! webui_service_running "nginx-dozzle"; then
		ECHO_ERROR "Dozzle is not running"
		return 1
	fi

	docker restart nginx-dozzle >/dev/null || return 1
	ECHO_SUCCESS "Dozzle restarted"
}

webui_system_action() {
	local id="${1:-}"
	local action="${2:-}"

	webui_cli_boot

	case "$id" in
	nginx)
		case "$action" in
		start)
			docker_nginx_start
			;;
		stop)
			webui_nginx_stop
			;;
		restart)
			docker_nginx_container
			if [[ "${NGINX_EXISTS:-0}" -ne 1 ]]; then
				ECHO_ERROR "Nginx container not running"
				return 1
			fi
			docker_nginx_restart
			;;
		*)
			ECHO_ERROR "Unknown Nginx action: ${action}"
			return 1
			;;
		esac
		;;
	dozzle)
		case "$action" in
		start)
			webui_dozzle_start
			;;
		stop)
			webui_dozzle_stop
			;;
		restart)
			webui_dozzle_restart
			;;
		*)
			ECHO_ERROR "Unknown Dozzle action: ${action}"
			return 1
			;;
		esac
		;;
	*)
		ECHO_ERROR "Unknown system service: ${id}"
		return 1
		;;
	esac
}

webui_compose_service() {
	local domain="${1:-}"
	local action="${2:-}"
	local service="${3:-}"
	local names=""

	webui_cli_boot
	webui_select_project "$domain" || return 1

	if [[ ! "$service" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]]; then
		ECHO_ERROR "Invalid service name"
		return 1
	fi

	if [[ -z "${PROJECT_DOCKER_DIR:-}" || ! -f "$PROJECT_DOCKER_DIR/docker-compose.yml" ]]; then
		ECHO_ERROR "Compose file not found"
		return 1
	fi

	names=$(docker_compose_output "config --services" "$PROJECT_DOCKER_DIR" 2>/dev/null || true)
	if ! printf '%s\n' "$names" | grep -qxF "$service"; then
		ECHO_ERROR "Unknown compose service: ${service}"
		return 1
	fi

	case "$action" in
	start)
		ECHO_YELLOW "docker compose start ${service}"
		docker_compose_runner "start ${service}" "$PROJECT_DOCKER_DIR" || return 1
		ECHO_SUCCESS "Started ${service}"
		;;
	stop)
		ECHO_YELLOW "docker compose stop ${service}"
		docker_compose_runner "stop ${service}" "$PROJECT_DOCKER_DIR" || return 1
		ECHO_SUCCESS "Stopped ${service}"
		;;
	*)
		ECHO_ERROR "Unknown service action: ${action}"
		return 1
		;;
	esac
}

webui_list_types() {
	local i json="[]"
	webui_cli_boot
	env_mode
	build_visible_projects

	for ((i = 0; i < ${#AVAILABLE_PROJECTS[@]}; i++)); do
		json=$(jq -nc --argjson acc "$json" --arg id "${AVAILABLE_PROJECTS[$i]}" --arg title "${PROJECT_TITLES[$i]}" \
			'$acc + [{id:$id,title:$title}]')
	done

	jq -n --argjson types "$json" --arg mode "${ENV_MODE:-}" '{ok:true,types:$types,mode:$mode}'
}

webui_create_project() {
	local type="${1:-}"
	local domain="${2:-}"
	local pair key value
	local allowed='^(PHP_VERSION|WP_VERSION|NODE_VERSION|NEXTJS_VERSION|DIRECTUS_VERSION|LARAVEL_VERSION|ELASTIC_VERSION|DB_NAME|TABLE_PREFIX|EMPTY_CONTENT|MULTISITE)$'

	webui_cli_boot
	env_mode
	build_visible_projects

	if [[ -z "$type" || -z "$domain" ]]; then
		ECHO_ERROR "Type and domain are required"
		return 1
	fi

	if ! printf '%s\n' "${AVAILABLE_PROJECTS[@]}" | grep -qx "$type"; then
		ECHO_ERROR "Unknown or unavailable project type: $type"
		return 1
	fi

	domain=$(printf '%s' "$domain" | tr '[:upper:]' '[:lower:]' | tr '_' '-' | cut -d . -f 1)
	if ! is_safe_hostname "$domain"; then
		ECHO_ERROR "Invalid domain name"
		return 1
	fi

	shift 2 || true
	for pair in "$@"; do
		[[ "$pair" == *"="* ]] || continue
		key="${pair%%=*}"
		value="${pair#*=}"
		if [[ ! "$key" =~ $allowed ]]; then
			ECHO_ERROR "Unsupported option: $key"
			return 1
		fi
		if [[ -n "$value" ]]; then
			printf -v "$key" '%s' "$value"
			export "$key"
		fi
	done

	: "${PHP_VERSION:=}"
	: "${WP_VERSION:=}"
	: "${DIRECTUS_VERSION:=}"
	: "${NODE_VERSION:=}"
	: "${NEXTJS_VERSION:=}"
	: "${ELASTIC_VERSION:=}"

	TEST_RUNNING=1
	SETUP_ACTION="create"
	SETUP_TYPE=1
	PROJECT_TYPE="$type"
	DOMAIN_NAME="$domain"
	get_domain_default_name
	DOMAIN_FULL="${DOMAIN_FULL:-$DOMAIN_NAME_DEFAULT}"

	ECHO_INFO "Creating $PROJECT_TYPE [$DOMAIN_NAME] as $DOMAIN_FULL"
	create_project_by_type "$type"
	local rc=$?
	TEST_RUNNING=0
	return "$rc"
}

webui_delete_project() {
	webui_cli_boot
	webui_select_project "${1:-}" || return 1
	INSTANCES_STATUS="remove"
	docker_delete_project
}

webui_dispatch() {
	local cmd="${1:-}"

	case "$cmd" in
	list)
		webui_list_projects
		;;
	types)
		webui_list_types
		;;
	create)
		webui_create_project "${@:2}"
		;;
	delete)
		webui_delete_project "${2:-}"
		;;
	start)
		webui_start_project "${2:-}"
		;;
	stop)
		webui_stop_project "${2:-}"
		;;
	restart)
		webui_restart_project "${2:-}"
		;;
	rebuild)
		webui_rebuild_project "${2:-}"
		;;
	bulk)
		webui_bulk_projects "${2:-}" "${3:-}"
		;;
	hosts)
		webui_hosts_extras "${2:-}" "${3:-}"
		;;
	system)
		webui_system_action "${2:-}" "${3:-}"
		;;
	service)
		webui_compose_service "${2:-}" "${3:-}" "${4:-}"
		;;
	*)
		echo '{"ok":false,"error":"unknown command"}' >&2
		return 1
		;;
	esac
}
