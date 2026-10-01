#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Drop non-printing characters, spaces, and leftover arrow-key fragments ([A [B [C [D).
sanitize_host_input() {
	local value="${1:-}"

	value=$(printf '%s' "$value" | tr -dc '[[:print:]]' | tr -d ' ')
	value=${value//\[A/}
	value=${value//\[B/}
	value=${value//\[C/}
	value=${value//\[D/}
	value=${value//_/-}
	printf '%s' "$value"
}

get_domain_name() {
	local fresh=0

	if [[ -z "${DOMAIN_NAME:-}" && -n "${CLI_NAME:-}" ]]; then
		DOMAIN_NAME="$CLI_NAME"
		fresh=1
	fi

	if [[ -z "${DOMAIN_NAME:-}" ]]; then
		if [[ ${CLI_NONINTERACTIVE:-0} -eq 1 ]]; then
			ECHO_ERROR "Site name is required. Use --name."
			return 1
		fi

		ECHO_ENTER "Enter Domain Name without subdomain:"
		read -rp 'Domain: ' DOMAIN_NAME
		fresh=1

		while [ -z "${DOMAIN_NAME:-}" ]; do
			read -rp "Please fill in the Domain: " DOMAIN_NAME
		done
	fi

	if [[ "$fresh" -eq 1 ]]; then
		DOMAIN_NAME=$(sanitize_host_input "$DOMAIN_NAME")
		DOMAIN_NAME=$(echo "${DOMAIN_NAME}" | cut -d . -f 1)

		if ! is_safe_hostname "$DOMAIN_NAME"; then
			ECHO_ERROR "Invalid domain name. Use letters, numbers, dots, and hyphens only."
			DOMAIN_NAME=""
			return 1
		fi
	fi
}

get_domain_default_name() {
	case "${PROJECT_TYPE:-}" in
	"elasticsearch")
		DOMAIN_NAME_DEFAULT="dev.$DOMAIN_NAME.elastic"
		;;
	*)
		DOMAIN_NAME_DEFAULT="dev.$DOMAIN_NAME.local"
		;;
	esac
}

check_domain_exists() {
	if [[ -z "${DOMAIN_NAME:-}" ]]; then
		echo "Error: DOMAIN_NAME is not set"
		return 1
	fi

	DOMAIN_CHECK=$(instances_get domain_name)

	if [[ "${DOMAIN_NAME:-}" == "$DOMAIN_CHECK" ]]; then
		DOMAIN_EXISTS=1
	else
		DOMAIN_EXISTS=0
	fi
}


# Reset a session variable to empty (never unset — nounset-safe).
reset_session_var() {
	local name="$1"

	is_safe_ident "$name" || return 1
	printf -v "$name" '%s' ''
	export "${name?}"
}

# Clear wizard / menu session state. Prefer this over bare unset under nounset.
unset_variables() {
	local extra="${1:-}"
	local name

	if [[ ${TEST_RUNNING:-0} -eq 1 ]]; then
		return 0
	fi

	for name in DOMAIN_NAME DB_NAME TABLE_PREFIX PHP_VERSION MULTISITE EMPTY_CONTENT SETUP_ACTION DOMAIN_MAIL; do
		reset_session_var "$name"
	done

	for name in $extra; do
		[[ -n "$name" ]] && reset_session_var "$name"
	done
}

get_project_type() {
	if [[ -z "${PROJECT_TYPE:-}" ]]; then
		PROJECT_TYPE=$(instances_get project_type)
	fi
}

get_compose_project_name() {
	if [[ -n "${DOMAIN_FULL:-}" ]]; then
		COMPOSE_PROJECT_NAME=$(echo "$DOMAIN_FULL" | sed "s/[^a-zA-Z0-9_\-]/_/g; s/^-//; s/-$/_/; s/-/_/g; s/[^a-zA-Z0-9_\-]//g; s/^$/none/")
	fi
}

delete_site_data() {
	if [ -d "$PROJECT_ROOT_DIR" ]; then
		EMPTY_LINE
		ECHO_YELLOW "Deleting Site files and webroot"
		rm -rf "$PROJECT_ROOT_DIR"
	else
		echo "Webroot not found"
	fi

	#Remove from instances.json
	update_file_instances

	#Remove from /etc/hosts
	setup_hosts_file rem
}

randpassword() {
	WP_PASSWORD=$(LC_CTYPE=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 20) || true
}

git_clone_templates_files() {
	local action=${1:-}

	if [[ $action == "copy" ]]; then
		# for development
		if [ -d "$ENV_DIR/../docker-env-templates/docker-env-template-$PROJECT_TYPE/" ]; then
			cp -r "$ENV_DIR/../docker-env-templates/docker-env-template-$PROJECT_TYPE/"* "$PROJECT_ROOT_DIR"
		else
			ECHO_ERROR "Please check you templates"
		fi
	else
		git clone "$TEMPLATES_REPO-$PROJECT_TYPE.git" "$PROJECT_ROOT_DIR" --depth 1
	fi
}
