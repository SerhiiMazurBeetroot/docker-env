#!/bin/bash

# Add or remove a vhost ex. dev.example.local. This will modify /etc/hosts

set -o errexit #to stop the script when an error occurs
set -o pipefail

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
		QUESTION=$1

		if [[ $QUESTION == "add" ]]; then

			HOSTS_LINE="$IP $DOMAIN_FULL $HOST_EXTRA"

			if [ -n "$(grep $DOMAIN_FULL /etc/hosts)" ]; then
				ECHO_WARN_RED "$DOMAIN_FULL already exists: $(grep $DOMAIN_FULL $ETC_HOSTS)"
			else
				ECHO_GREEN "Adding $DOMAIN_FULL to your $ETC_HOSTS"
				EMPTY_LINE
				sudo -- sh -c -e "echo '$HOSTS_LINE' >> /etc/hosts"

				if [ -n "$(grep $DOMAIN_FULL /etc/hosts)" ]; then
					ECHO_SUCCESS "$DOMAIN_FULL was added succesfully \n $(grep $DOMAIN_FULL /etc/hosts)"
				else
					ECHO_ERROR "Failed to Add $DOMAIN_FULL, Try again!"
				fi
			fi

		fi

		if [[ $QUESTION == "rem" ]]; then

			if [ -n "$(grep $DOMAIN_FULL /etc/hosts)" ]; then
				ECHO_GREEN "$DOMAIN_FULL Found in your $ETC_HOSTS, Removing now..."
				sudo sed -i".bak" "/$DOMAIN_FULL/d" $ETC_HOSTS
				EMPTY_LINE
			else
				ECHO_ERROR "$DOMAIN_FULL was not found in your $ETC_HOSTS"
			fi

		fi
	fi

	sleep 1
}
