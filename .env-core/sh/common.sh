#!/bin/bash

set -o errexit  # Stop the script when an error occurs
set -o pipefail # Fail on pipe errors

# nounset is enabled after const + menus load (see autoloader.sh).
if [[ "${ENV_CORE_INITIALIZED:-0}" -eq 1 ]]; then
	set -o nounset
fi

# Optional: Enable debug mode if DEBUG environment variable is set
[[ "${DEBUG:-}" == "true" ]] && set -o xtrace

# Helper function to safely reference arrays (for nounset mode)
# Usage: for item in $(safe_array "${my_array[@]+"${my_array[@]}"}"); do
safe_array() {
	printf '%s\n' "$@"
}
