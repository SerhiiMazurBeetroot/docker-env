#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Command router for webui_cli.sh.
# Handlers live in the sibling scripts in this directory. load_system_modules
# sources every *.sh here, so this file only dispatches.

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
