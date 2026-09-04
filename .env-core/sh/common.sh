#!/bin/bash

set -o errexit  # Stop the script when an error occurs
set -o pipefail # Fail on pipe errors
# set -o nounset  # Fail on unset variables

# Optional: Enable debug mode if DEBUG environment variable is set
[[ "${DEBUG:-}" == "true" ]] && set -o xtrace

# Helper function to safely reference arrays (for nounset mode)
# Usage: for item in $(safe_array "${my_array[@]+"${my_array[@]}"}"); do
safe_array() {
	printf '%s\n' "$@"
}
