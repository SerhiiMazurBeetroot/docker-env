#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

webui_hosts_path() {
	if [[ -e /host-etc-hosts ]]; then
		printf '%s' /host-etc-hosts
		return 0
	fi
	if [[ -e /.dockerenv ]]; then
		printf ''
		return 1
	fi
	printf '%s' /etc/hosts
}

webui_hosts_rewrite() {
	local file="$1"
	local action="$2"
	local site="$3"
	shift 3
	local extras=("$@")
	local tmp extra_csv

	if [[ ! -f "$file" ]]; then
		ECHO_ERROR "Hosts file not found: $file"
		return 1
	fi

	if [[ ! -w "$file" ]]; then
		ECHO_ERROR "Hosts file is not writable from Web UI ($file)."
		ECHO_YELLOW "Mount /etc/hosts at /host-etc-hosts on the webui container, or run setup from the CLI."
		return 1
	fi

	extra_csv=$(IFS=,; printf '%s' "${extras[*]}")
	tmp=$(mktemp)
	awk -v action="$action" -v site="$site" -v extra_csv="$extra_csv" '
		BEGIN { n = split(extra_csv, extras, ","); changed = 0 }
		{
			line = $0
			sub(/#.*/, "", line)
			if (line ~ /^[[:space:]]*$/) { print $0; next }
			found = 0
			for (i = 2; i <= NF; i++) if ($i == site) found = 1
			if (!found) { print $0; next }
			out = $1
			for (i = 2; i <= NF; i++) {
				tok = $i
				if (tok ~ /^#/) break
				skip = 0
				if (action == "rem") {
					for (j = 1; j <= n; j++) if (tok == extras[j]) skip = 1
				}
				if (skip) continue
				out = out " " tok
			}
			if (action == "add") {
				for (j = 1; j <= n; j++) {
					if (extras[j] == "") continue
					has = 0
					split(out, of, " ")
					for (k in of) if (of[k] == extras[j]) has = 1
					if (!has) out = out " " extras[j]
				}
			}
			print out
			changed = 1
			next
		}
		END {
			if (action == "add" && changed == 0) {
				line = "127.0.0.1 " site
				for (j = 1; j <= n; j++) if (extras[j] != "") line = line " " extras[j]
				print line
			}
		}
	' "$file" >"$tmp" || {
		rm -f "$tmp"
		return 1
	}

	cat "$tmp" >"$file" || {
		rm -f "$tmp"
		ECHO_ERROR "Failed to write $file"
		return 1
	}
	rm -f "$tmp"
	return 0
}

webui_hosts_extras() {
	local action="${1:-}"
	local domain="${2:-}"
	local file
	local extras=()

	webui_cli_boot
	webui_select_project "$domain" || return 1

	case "$action" in
	add | rem) ;;
	*)
		ECHO_ERROR "Unknown hosts action: ${action}"
		return 1
		;;
	esac

	file=$(webui_hosts_path) || true
	if [[ -z "$file" ]]; then
		ECHO_ERROR "Host /etc/hosts is not mounted at /host-etc-hosts."
		ECHO_YELLOW "Recreate the Web UI container so the new volume is attached."
		return 1
	fi
	# shellcheck disable=SC2206
	extras=(${HOST_EXTRA:-})

	if [[ ${#extras[@]} -eq 0 ]]; then
		ECHO_YELLOW "No extra hosts for ${PROJECT_TYPE:-this project} (phpMyAdmin, Kibana, …)"
		return 0
	fi

	ECHO_YELLOW "${action} extras for ${DOMAIN_FULL} in ${file}"
	ECHO_KEY_VALUE "Extras" "${extras[*]}"
	webui_hosts_rewrite "$file" "$action" "$DOMAIN_FULL" "${extras[@]}" || return 1
	ECHO_SUCCESS "Updated hosts for ${DOMAIN_FULL}"
	grep -n -- "$DOMAIN_FULL" "$file" || true
}
