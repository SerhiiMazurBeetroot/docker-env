#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

site_type_label() {
	local label=""

	if label=$(project_field label "${1:-}"); then
		printf '%s' "$label"
		return 0
	fi

	printf '%s' "${1:-}"
}

site_run_label() {
	if container_is_running; then
		printf 'running'
	else
		printf 'stopped'
	fi
}

site_link_line() {
	local -a bits=()
	local path suffix

	if [[ -n "${DOMAIN_ADMIN:-}" ]]; then
		if [[ "$DOMAIN_ADMIN" == *"/"* ]]; then
			path="/${DOMAIN_ADMIN#*/}"
			case "$path" in
			/login) bits+=("login  /login") ;;
			*) bits+=("admin  $path") ;;
			esac
		else
			suffix="${DOMAIN_ADMIN#"$DOMAIN_FULL"}"
			suffix="${suffix#.}"
			[[ -n "$suffix" ]] && bits+=("admin  $suffix")
		fi
	fi

	if [[ -n "${DOMAIN_DB:-}" ]]; then
		suffix="${DOMAIN_DB#"$DOMAIN_FULL"}"
		suffix="${suffix#.}"
		[[ -n "$suffix" ]] && bits+=("database  $suffix")
	fi

	if [[ -n "${DOMAIN_MAIL:-}" ]]; then
		suffix="${DOMAIN_MAIL#"$DOMAIN_FULL"}"
		suffix="${suffix#.}"
		if [[ "$suffix" == "mail" ]]; then
			bits+=("mail  mailhog")
		elif [[ -n "$suffix" ]]; then
			bits+=("mail  $suffix")
		fi
	fi

	if ((${#bits[@]} == 0)); then
		return 0
	fi

	local joined
	joined=$(printf '%s     ' "${bits[@]}")
	joined="${joined%     }"
	printf '%b%s%b\n' "$YELLOW" "$joined" "$NC"
}

site_menu_row() {
	local num="$1"
	local label="$2"
	local hint="${3:-}"
	local color="${4:-$GREEN}"

	if [[ -n "$hint" ]]; then
		printf '%b[%s]%b %-16s %b%s%b\n' "$color" "$num" "$NC" "$label" "$CYAN" "$hint" "$NC"
	else
		printf '%b[%s]%b %s\n' "$color" "$num" "$NC" "$label"
	fi
}

site_menu() {
	load_project_modules

	if [[ -z "${DOMAIN_NAME:-}" ]]; then
		return 0
	fi

	local label url
	label=$(site_type_label "${PROJECT_TYPE:-}")
	url="https://${DOMAIN_FULL:-}"

	while true; do
		local -a labels=()
		local -a keys=()
		local -a hints=()
		local index action key
		local action_label action_hint action_cmd

		labels+=("Open site")
		keys+=("open")
		hints+=("")

		if container_is_running; then
			labels+=("Stop")
			keys+=("stop")
		else
			labels+=("Start")
			keys+=("start")
		fi
		hints+=("")

		labels+=("Shell")
		keys+=("shell")
		hints+=("")

		labels+=("Database")
		keys+=("database")
		hints+=("")

		while IFS=$'\t' read -r action_label action_hint action_cmd; do
			[[ -n "$action_cmd" ]] || continue
			labels+=("$action_label")
			keys+=("$action_cmd")
			hints+=("$action_hint")
		done < <(site_actions_for_type "${PROJECT_TYPE:-}")

		labels+=("More")
		keys+=("more")
		hints+=("restart, git, archive, remove")

		EMPTY_LINE
		ECHO_CYAN "==== ${DOMAIN_NAME} · ${label} · $(site_run_label) ===="
		ECHO_GREEN "$url"
		site_link_line
		ECHO_YELLOW "[0] Sites"

		for ((index = 0; index < ${#labels[@]}; index++)); do
			site_menu_row "$((index + 1))" "${labels[$index]}" "${hints[$index]}"
		done

		action=$(GET_USER_INPUT "select_one_of")
		action="${action:-0}"

		if [[ "$action" == "0" ]]; then
			return 0
		fi

		if ((action < 1 || action > ${#keys[@]})); then
			ECHO_WARN_RED "Wrong option"
			continue
		fi

		key="${keys[$((action - 1))]}"
		case "$key" in
		open)
			site_open
			;;
		start)
			docker_start_project
			;;
		stop)
			database_auto_backup
			docker_stop
			;;
		shell)
			site_shell
			;;
		database)
			site_database_menu
			;;
		more)
			if site_more_menu; then
				return
			fi
			;;
		*)
			if declare -F "$key" >/dev/null 2>&1; then
				"$key"
			else
				ECHO_WARN_RED "Unknown action: $key"
			fi
			;;
		esac
	done
}

site_open_url() {
	local url="$1"

	if [[ -z "$url" ]]; then
		ECHO_ERROR "Site URL is not set"
		return 1
	fi

	ECHO_INFO "$url"

	if [[ "${OSTYPE:-}" == darwin* ]]; then
		open "$url" >/dev/null 2>&1 || true
	elif command -v xdg-open >/dev/null 2>&1; then
		xdg-open "$url" >/dev/null 2>&1 || true
	fi
}

site_open() {
	if [[ -z "${DOMAIN_FULL:-}" ]]; then
		ECHO_ERROR "Site URL is not set"
		return 1
	fi

	site_open_url "https://${DOMAIN_FULL}"
}

site_more_menu() {
	while true; do
		local status mark action
		status=$(instances_get status || true)

		if [[ "$status" == "inactive" ]]; then
			mark="Mark active"
		else
			mark="Mark inactive"
		fi

		EMPTY_LINE
		ECHO_CYAN "==== ${DOMAIN_NAME} · More ===="
		ECHO_YELLOW "[0] Return to the site"
		ECHO_GREEN "[1] Restart"
		ECHO_GREEN "[2] Rebuild"
		ECHO_GREEN "[3] Git"
		ECHO_GREEN "[4] Archive"
		ECHO_GREEN "[5] ${mark}"
		ECHO_RED "[6] Remove site"

		action=$(GET_USER_INPUT "select_one_of")

		case "${action:-0}" in
		0)
			return 1
			;;
		1)
			docker_restart
			;;
		2)
			docker_rebuild
			docker_restart
			;;
		3)
			git_menu
			;;
		4)
			zip_menu
			;;
		5)
			site_toggle_status
			;;
		6)
			if site_remove; then
				return 0
			fi
			;;
		*)
			ECHO_WARN_RED "Wrong option"
			;;
		esac
	done
}

site_toggle_status() {
	local current
	current=$(instances_get status || true)

	if [[ "$current" == "active" ]]; then
		INSTANCES_STATUS="inactive"
	elif [[ "$current" == "inactive" ]]; then
		INSTANCES_STATUS="active"
	else
		ECHO_WARN_RED "This site cannot be marked ${current:-unknown}"
		return 1
	fi

	update_file_instances
	ECHO_SUCCESS "Site is now ${INSTANCES_STATUS}"
}

site_shell() {
	if ! container_is_running; then
		ECHO_ERROR "Site is not running. Start it first."
		return 1
	fi

	ECHO_INFO "[exit] to leave the container shell"
	docker exec -it "$DOCKER_CONTAINER_APP" sh
}

site_database_menu() {
	while true; do
		EMPTY_LINE
		ECHO_CYAN "==== ${DOMAIN_NAME} · Database ===="
		ECHO_YELLOW "[0] Return to the site"
		ECHO_GREEN "[1] Import"
		ECHO_GREEN "[2] Export"
		ECHO_GREEN "[3] Search-Replace"
		ECHO_GREEN "[4] Replace project from DB"

		local action
		action=$(GET_USER_INPUT "select_one_of")

		case "${action:-0}" in
		0)
			return 0
			;;
		1)
			database_import
			;;
		2)
			database_export
			;;
		3)
			database_search_replace
			;;
		4)
			site_replace_project_from_db
			;;
		*)
			ECHO_WARN_RED "Wrong option"
			;;
		esac
	done
}

# Same steps as the old database menu, applied to the site already open.
site_replace_project_from_db() {
	if [[ ! -d "${PROJECT_DATABASE_DIR:-}" ]]; then
		ECHO_ERROR "DB directory not found: ${PROJECT_DATABASE_DIR:-}"
		return 1
	fi

	database_replace_project_from_db || return 1
	docker_rebuild || return 1
	docker_restart || return 1
	database_import || return 1

	case "${PROJECT_TYPE:-}" in
	wordpress | projects | bedrock | wordpress_nextjs)
		fix_permissions || true
		edit_file_wp_config_setup_beetroot
		wp_get_default_theme
		wp_composer_install
		edit_file_env_setup_beetroot
		fix_linux_watchers
		edit_file_gitignore
		;;
	esac

	ECHO_SUCCESS "Project replaced from the database dump"
}

site_remove() {
	local yn

	yn=$(GET_USER_INPUT "question" "Delete ${DOMAIN_NAME}? Containers, volumes, and site files will be removed." "n")
	if [[ ! "$yn" =~ ^[Yy]$ ]]; then
		ECHO_INFO "Cancelled"
		return 1
	fi

	docker_delete_project
	unset_variables "PROJECT_TYPE"
	return 0
}
