#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Project types exercised by the smoke suite (stable + WIP in development).
tests_build_project_types() {
	TESTS_PROJECT_TYPES=("${STABLE_PROJECTS[@]}")

	if is_env_development; then
		TESTS_PROJECT_TYPES+=("${WIP_PROJECTS[@]}")
	fi
}

tests_prepare_project() {
	local type="$1"

	PROJECT_TYPE="$type"
	DOMAIN_NAME="$type-test"
	SETUP_TYPE=1
	TEST_RUNNING=1
	SETUP_ACTION="create"

	# Prior test compose teardown must not leave interpolation vars unset (nounset-safe).
	: "${WP_VERSION:=}"
	: "${PHP_VERSION:=}"
	: "${DIRECTUS_VERSION:=}"
	: "${NODE_VERSION:=}"
	: "${NEXTJS_VERSION:=}"
	: "${ELASTIC_VERSION:=}"

	get_domain_default_name
	DOMAIN_FULL="$DOMAIN_NAME_DEFAULT"
	set_project_args
	get_project_dir "skip_question"
}

tests_reset_project_globals() {
	TEST_RUNNING=0
	unset_variables "PROJECT_TYPE"
}

tests_project_compose_dir() {
	case "${PROJECT_TYPE:-}" in
	nodejs | nodejs_api)
		printf '%s' "$PROJECT_ROOT_DIR"
		;;
	wordpress | projects)
		printf '%s' "$PROJECT_ROOT_DIR/wp-docker"
		;;
	*)
		printf '%s' "${PROJECT_DOCKER_DIR:-$PROJECT_ROOT_DIR/docker}"
		;;
	esac
}

tests_container_running() {
	local name="$1"

	[[ -n "$name" ]] || return 1
	docker ps --format '{{.Names}}' | grep -qE "(^|_|-)${name}($)"
}

tests_wait_http() {
	local url="$1"
	local attempts="${2:-45}"
	local i code

	for ((i = 1; i <= attempts; i++)); do
		code=$(curl -k -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null || echo "000")
		if [[ "$code" =~ ^[23] ]]; then
			return 0
		fi
		sleep 2
	done

	ECHO_ERROR "HTTP unhealthy: $url (last status: ${code:-none})"
	return 1
}

tests_assert_instance_row() {
	local status type

	status=$(instances_get status)
	type=$(instances_get project_type)

	if [[ "$status" != "active" ]]; then
		ECHO_ERROR "instances.log status is not active for $DOMAIN_NAME (got: ${status:-empty})"
		return 1
	fi

	if [[ "$type" != "$PROJECT_TYPE" ]]; then
		ECHO_ERROR "instances.log project_type mismatch for $DOMAIN_NAME (expected $PROJECT_TYPE, got: ${type:-empty})"
		return 1
	fi

	return 0
}

tests_assert_containers_running() {
	case "${PROJECT_TYPE:-}" in
	directus_nextjs)
		tests_container_running "${DOMAIN_NAME}-directus" || {
			ECHO_ERROR "Container not running: ${DOMAIN_NAME}-directus"
			return 1
		}
		tests_container_running "${DOMAIN_NAME}-mysql" || {
			ECHO_ERROR "Container not running: ${DOMAIN_NAME}-mysql"
			return 1
		}
		;;
	*)
		if [[ -z "${DOCKER_CONTAINER_APP:-}" ]]; then
			ECHO_ERROR "DOCKER_CONTAINER_APP is not set for $PROJECT_TYPE"
			return 1
		fi

		tests_container_running "$DOCKER_CONTAINER_APP" || {
			ECHO_ERROR "Container not running: $DOCKER_CONTAINER_APP"
			return 1
		}

		if [[ "${DB_TYPE:-0}" != "0" && -n "${DOCKER_CONTAINER_DB:-}" ]]; then
			tests_container_running "$DOCKER_CONTAINER_DB" || {
				ECHO_ERROR "Container not running: $DOCKER_CONTAINER_DB"
				return 1
			}
		fi
		;;
	esac

	return 0
}

tests_assert_compose_healthy() {
	local dir exited

	dir=$(tests_project_compose_dir)

	if [[ ! -f "$dir/docker-compose.yml" ]]; then
		ECHO_ERROR "docker-compose.yml not found: $dir"
		return 1
	fi

	exited=$(docker_compose_output "ps -a --status exited -q" "$dir" 2>/dev/null | wc -l | tr -d '[:space:]')
	if [[ "${exited:-0}" -gt 0 ]]; then
		ECHO_ERROR "Compose has exited services in $dir"
		docker_compose_output "ps -a" "$dir" 2>/dev/null || true
		return 1
	fi

	return 0
}

tests_assert_http() {
	local url="https://${DOMAIN_FULL}"

	case "${PROJECT_TYPE:-}" in
	elasticsearch)
		if [[ -n "${DOMAIN_KIBANA:-}" ]]; then
			url="https://${DOMAIN_KIBANA}"
		fi
		;;
	directus | directus_nextjs)
		url="https://${DOMAIN_FULL}/server/health"
		;;
	esac

	tests_wait_http "$url" || return 1
	return 0
}

# Table-driven post-create checks for one project type.
tests_assert_project_healthy() {
	local type="$1"
	local failed=0

	ECHO_INFO "Health checks: $type ($DOMAIN_FULL)"

	tests_assert_instance_row || failed=1
	tests_assert_containers_running || failed=1
	tests_assert_compose_healthy || failed=1
	tests_assert_http || failed=1

	if [[ $failed -ne 0 ]]; then
		ECHO_ERROR "Health checks failed: $type"
		return 1
	fi

	ECHO_SUCCESS "Health checks passed: $type"
	return 0
}

tests_remove_db_volumes() {
	local volume

	[[ -n "${DOCKER_VOLUME_DB:-}" ]] || return 0

	while IFS= read -r volume; do
		[[ -n "$volume" ]] && docker volume rm "$volume" 2>/dev/null || true
	done < <(docker volume ls --format '{{.Name}}' | grep -E "(^|_)${DOCKER_VOLUME_DB}($)" || true)
}

tests_docker_cleanup() {
	local dir

	dir=$(tests_project_compose_dir)

	if [[ -f "$dir/docker-compose.yml" ]]; then
		docker_compose_runner "down -v --remove-orphans" "$dir" 2>/dev/null || true
	fi

	tests_remove_db_volumes
}

tests_teardown_project() {
	INSTANCES_STATUS="remove"
	tests_docker_cleanup
	delete_site_data 2>/dev/null || true
}

tests_create_one_project() {
	local type="$1"

	tests_prepare_project "$type"
	tests_teardown_project

	if ! create_project_by_type "$type"; then
		ECHO_ERROR "Create failed: $type"
		return 1
	fi

	tests_assert_project_healthy "$type"
}

tests_print_summary() {
	local label="$1"
	shift
	local failed=("$@")

	EMPTY_LINE
	if [[ ${#failed[@]} -eq 0 ]]; then
		ECHO_SUCCESS "$label — all passed"
		return 0
	fi

	ECHO_ERROR "$label — ${#failed[@]} failed:"
	for type in "${failed[@]}"; do
		ECHO_ERROR "  - $type"
	done
	return 1
}
