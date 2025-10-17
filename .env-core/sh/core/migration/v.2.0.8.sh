#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

update_system_2_0_8() {
	ECHO_YELLOW "Running migration..."

	local base_src="$ENV_DIR/.env-core"
	local services=("nginx" "nghost" "ngrok")

	for service in "${services[@]}"; do
		local src="$base_src/$service"

		EMPTY_LINE
		ECHO_INFO "Stopping '$service' service..."
		if cd "$src" 2>/dev/null; then
			if $DOCKER_COMPOSE_CMD down; then
				ECHO_CYAN "[$service] stopped successfully."
			fi
		else
			continue
		fi

		ECHO_CYAN "Cleaning up old '$service' directory..."
		if rm -rf "$src"; then
			ECHO_CYAN "Removed [$src]"
		else
			ECHO_RED "Failed to remove [$src]"
		fi
	done
}
