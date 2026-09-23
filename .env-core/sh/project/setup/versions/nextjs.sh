#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

get_nextjs_version() {
	QUESTION=${1:-}

	pkg="create-next-app"
	data=$(curl -s "https://registry.npmjs.org/$pkg")

	if [ -z "$data" ]; then
		echo "Error: no data from npm registry"
		return 1
	fi

	# all stable versions
	versions=$(echo "$data" | jq -r '.versions | keys[]' | grep -vE '-')

	# major versions
	majors=$(echo "$versions" | cut -d. -f1 | sort -Vr | uniq | head -n 3)

	LIST=()

	for major in $majors; do
		latest=$(echo "$versions" | grep -E "^${major}\." | sort -Vr | head -n 1)
		LIST+=("$latest")
	done

	DEFAULT_VERSION="${LIST[0]}"

	if [[ -z "${NEXTJS_VERSION:-}" ]]; then
		if [[ $QUESTION == "default" ]]; then
			NEXTJS_VERSION="$DEFAULT_VERSION"
		else
			ECHO_ENTER "Enter NEXTJS_VERSION [default '$DEFAULT_VERSION']"
			print_list "${LIST[@]}"

			choice=$(GET_USER_INPUT "select_one_of")
			choice=${choice%.*}

			if [ -z "$choice" ]; then
				NEXTJS_VERSION="$DEFAULT_VERSION"
			elif ((choice > 0 && choice <= ${#LIST[@]})); then
				NEXTJS_VERSION="${LIST[$((choice - 1))]}"
			else
				ECHO_WARN_RED "Invalid choice. Using default: $DEFAULT_VERSION"
				NEXTJS_VERSION="$DEFAULT_VERSION"
			fi
		fi
	fi
}
