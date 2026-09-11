#!/bin/bash

# Add or remove a vhost ex. dev.example.local. This will modify /etc/hosts

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

setup_hosts_file() {
	case $OSTYPE in
	"linux" | "darwin")
		ETC_HOSTS="/etc/hosts"
		;;
	"windows")
		ETC_HOSTS="/c/Windows/System32/drivers/etc/hosts"
		;;
	esac

	if [[ $ETC_HOSTS ]]; then
		IP="127.0.0.1"
		QUESTION=${1:-}

		if ! is_safe_hostname "${DOMAIN_FULL:-}"; then
			ECHO_ERROR "Refusing to edit hosts: invalid DOMAIN_FULL"
			return 1
		fi

		if [[ $QUESTION == "add" ]]; then

			HOSTS_LINE="${IP:-} ${DOMAIN_FULL:-} ${HOST_EXTRA:-}"

			if grep -Fq -- "$DOMAIN_FULL" "$ETC_HOSTS"; then
				ECHO_WARN_RED "$DOMAIN_FULL already exists: $(grep -F -- "$DOMAIN_FULL" "$ETC_HOSTS")"
			else
				ECHO_GREEN "Adding $DOMAIN_FULL to your $ETC_HOSTS"
				EMPTY_LINE
				printf '%s\n' "$HOSTS_LINE" | sudo tee -a "$ETC_HOSTS" >/dev/null

				if grep -Fq -- "$DOMAIN_FULL" "$ETC_HOSTS"; then
					ECHO_SUCCESS "$DOMAIN_FULL was added succesfully \n $(grep -F -- "$DOMAIN_FULL" "$ETC_HOSTS")"
				else
					ECHO_ERROR "Failed to Add $DOMAIN_FULL, Try again!"
				fi
			fi

		fi

		if [[ $QUESTION == "rem" ]]; then

			if grep -Fq -- "$DOMAIN_FULL" "$ETC_HOSTS"; then
				ECHO_GREEN "$DOMAIN_FULL Found in your $ETC_HOSTS, Removing now..."
				sudo sed -i.bak "/$(printf '%s' "$DOMAIN_FULL" | sed 's/[.[\*^$]/\\&/g')/d" "$ETC_HOSTS"
				EMPTY_LINE
			else
				ECHO_ERROR "$DOMAIN_FULL was not found in your $ETC_HOSTS"
			fi

		fi
	fi

	sleep 1
}
