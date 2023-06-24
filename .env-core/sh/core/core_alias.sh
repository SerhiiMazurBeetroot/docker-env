#!/bin/bash

set -o errexit #to stop the script when an error occurs
set -o pipefail

add_alias() {
    EMPTY_LINE

    ALIAS_EXISTS=$(awk '/ALIAS_CMD/{print $1}' "$FILE_SETTINGS" | sed 's/'ALIAS_CMD='//')

    if [[ -n "$ALIAS_EXISTS" ]]; then
        return
    fi

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
        # (~/.bashrc for Bash or ~/.zshrc for Zsh)
        if grep -q "# BEGIN SNIPPET: $ALIAS_CMD" ~/.bashrc; then
            ECHO_INFO "$logExist"
        else
            {
                echo "
# BEGIN SNIPPET: $ALIAS_CMD
export DOCKER_ENV_DIR='$ENV_DIR'
alias $ALIAS_CMD='$SCRIPT_PATH'
# END SNIPPET: $ALIAS_CMD"
            } >>~/.bashrc

            source ~/.bashrc

            save_settings "ALIAS_CMD=$ALIAS_CMD"

            ECHO_INFO "$logAdded"
        fi
    else
        ECHO_INFO "Unsupported operating system: $OSTYPE"
    fi
}
