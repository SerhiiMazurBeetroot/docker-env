#!/bin/bash

# Add or remove a vhost ex. dev.example.local. This will modify /etc/hosts

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# A name counts only as its own token. dev.site.local.pgadmin must not hide dev.site.local.
_hosts_has_token() {
	local file="$1"
	local name="$2"

	awk -v name="$name" '
		{
			sub(/#.*/, "")
			for (i = 2; i <= NF; i++) if ($i == name) found = 1
		}
		END { exit found ? 0 : 1 }
	' "$file"
}

_hosts_append_line() {
	local file="$1"
	local line="$2"
	local privileged="$3"

	if [[ "$privileged" -eq 1 ]]; then
		printf '%s\n' "$line" | sudo tee -a "$file" >/dev/null
		return $?
	fi

	printf '%s\n' "$line" >>"$file"
}

_hosts_remove_line() {
	local file="$1"
	local site="$2"
	local privileged="$3"
	local tmp

	if [[ "$privileged" -eq 1 ]]; then
		sudo sed -i.bak "/$(printf '%s' "$site" | sed 's/[.[\*^$]/\\&/g')/d" "$file"
		return $?
	fi

	tmp=$(mktemp)
	grep -Fv -- "$site" "$file" >"$tmp" || true
	cat "$tmp" >"$file"
	rm -f "$tmp"
}

setup_hosts_file() {
	local question="${1:-}"
	local file=""
	local privileged=0
	local IP="127.0.0.1"

	# The Web UI container mounts the Mac hosts file here. Its own /etc/hosts is not the one the browser uses.
	# test -w on that mount can be true while macOS still rejects the write, so the append result is what counts.
	if [[ -e /host-etc-hosts ]]; then
		file="/host-etc-hosts"
	else
		detect_os
		case "${OSTYPE:-}" in
		linux* | darwin*)
			file="/etc/hosts"
			# Group-writable hosts (root:staff) can be updated without sudo.
			# sudo from the Web UI has no password prompt, so that path was skipped.
			if [[ ! -w "$file" ]]; then
				privileged=1
			fi
			;;
		windows)
			file="/c/Windows/System32/drivers/etc/hosts"
			privileged=1
			;;
		*)
			ECHO_ERROR "Cannot update the hosts file on this system (${OSTYPE:-unknown})."
			return 1
			;;
		esac
	fi

	ETC_HOSTS="$file"

	if ! is_safe_hostname "${DOMAIN_FULL:-}"; then
		ECHO_ERROR "Refusing to edit hosts: invalid DOMAIN_FULL"
		return 1
	fi

	if [[ $question == "add" ]]; then
		HOSTS_LINE="${IP} ${DOMAIN_FULL} ${HOST_EXTRA:-}"

		if _hosts_has_token "$ETC_HOSTS" "$DOMAIN_FULL"; then
			ECHO_WARN_RED "$DOMAIN_FULL already exists: $(grep -F -- "$DOMAIN_FULL" "$ETC_HOSTS")"
		else
			ECHO_GREEN "Adding $DOMAIN_FULL to your $ETC_HOSTS"
			EMPTY_LINE
			_hosts_append_line "$ETC_HOSTS" "$HOSTS_LINE" "$privileged" || {
				ECHO_ERROR "Failed to add $DOMAIN_FULL to $ETC_HOSTS."
				ECHO_YELLOW "The Web UI writes that file as your Mac user. /etc/hosts is owned by root, so the write is denied until your user can write it."
				ECHO_TEXT "$HOSTS_LINE"
				return 1
			}

			if _hosts_has_token "$ETC_HOSTS" "$DOMAIN_FULL"; then
				ECHO_SUCCESS "$DOMAIN_FULL was added succesfully \n $(grep -F -- "$DOMAIN_FULL" "$ETC_HOSTS")"
			else
				ECHO_ERROR "Failed to add $DOMAIN_FULL to $ETC_HOSTS."
				ECHO_YELLOW "The Web UI writes that file as your Mac user. /etc/hosts is owned by root, so the write is denied until your user can write it."
				ECHO_TEXT "$HOSTS_LINE"
				return 1
			fi
		fi
	fi

	if [[ $question == "rem" ]]; then
		if _hosts_has_token "$ETC_HOSTS" "$DOMAIN_FULL"; then
			ECHO_GREEN "$DOMAIN_FULL Found in your $ETC_HOSTS, Removing now..."
			_hosts_remove_line "$ETC_HOSTS" "$DOMAIN_FULL" "$privileged" || return 1
			EMPTY_LINE
		else
			ECHO_ERROR "$DOMAIN_FULL was not found in your $ETC_HOSTS"
		fi
	fi

	sleep 1
}
