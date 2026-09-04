#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

add_alias() {
	EMPTY_LINE

	ALIAS_EXISTS=$(awk -F= '/^ALIAS_CMD=/{print $2}' "$FILE_SETTINGS" 2>/dev/null || true)
	[[ -n "$ALIAS_EXISTS" ]] && return

	ENV_DIR="$PWD"
	SCRIPT_PATH="$ENV_DIR/setup.sh"
	local logExist="Alias '$ALIAS_CMD' already exists."
	local logAdded="Alias '$ALIAS_CMD' added"

	if [[ "$OSTYPE" == "windows" ]]; then
		# Command Prompt or PowerShell
		if doskey /macros | grep -q "$ALIAS_CMD"; then
			ECHO_INFO "$logExist"
		else
			# Define the alias using doskey command in Command Prompt
			echo "doskey $ALIAS_CMD=$SCRIPT_PATH" >>%USERPROFILE%\dockerenv.bat

			save_settings "ALIAS_CMD=$ALIAS_CMD"

			ECHO_INFO "$logAdded"
		fi
	elif [[ "$OSTYPE" == "darwin" || $OSTYPE == "linux" ]]; then

		RC_FILE="$HOME/.profile"

		case "$(basename "${SHELL-}")" in
		zsh) RC_FILE="$HOME/.zshrc" ;;
		bash) RC_FILE="$HOME/.bashrc" ;;
		esac

		touch "$RC_FILE"

		if grep -q "# BEGIN SNIPPET: $ALIAS_CMD" "$RC_FILE"; then
			ECHO_INFO "$logExist"
			return
		fi

		{
			echo ""
			echo "# BEGIN SNIPPET: $ALIAS_CMD"
			echo "export DOCKER_ENV_DIR=\"$ENV_DIR\""
			echo "alias $ALIAS_CMD='\"$SCRIPT_PATH\"'"
			echo "# END SNIPPET: $ALIAS_CMD"
		} >>"$RC_FILE"

		save_settings "ALIAS_CMD=$ALIAS_CMD"

		ECHO_INFO "$logAdded"
		ECHO_INFO "Restart terminal or run: source $RC_FILE"

	else
		ECHO_INFO "Unsupported OS: $OSTYPE"
	fi
}
