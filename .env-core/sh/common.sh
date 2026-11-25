#!/bin/bash

set -o errexit  # Stop the script when an error occurs
set -o pipefail # Fail on pipe errors

# nounset is enabled after const + menus load (see autoloader.sh).
if [[ "${ENV_CORE_INITIALIZED:-0}" -eq 1 ]]; then
	set -o nounset
fi

# Optional: Enable debug mode if DEBUG environment variable is set.
# Keep this an `if`: as the last line of a sourced file, `[[ ]] && ...` returns 1
# when DEBUG is unset, and with errexit that aborts every script sourcing common.sh.
if [[ "${DEBUG:-}" == "true" ]]; then
	set -o xtrace
fi
