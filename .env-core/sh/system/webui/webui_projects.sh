#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

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
