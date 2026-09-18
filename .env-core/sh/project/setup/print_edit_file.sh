#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

update_file_instances() {
	case $INSTANCES_STATUS in
	"remove")
		instances_remove
		;;
	"archive" | "active" | "inactive")
		instances_set_status "$INSTANCES_STATUS"
		;;
	*)
		echo "Invalid status: $INSTANCES_STATUS"
		;;
	esac
}

replace_templates_files() {
	local search_dir="${PROJECT_DOCKER_DIR:-$PROJECT_ROOT_DIR}"
	local EXAMPLE_FILES=()

	if [[ -d "$search_dir" ]]; then
		while IFS= read -r -d '' example; do
			EXAMPLE_FILES+=("$example")
		done < <(find "$search_dir" -type f -name '*.example' -print0 2>/dev/null)
	fi

	if [[ ${#EXAMPLE_FILES[@]} -eq 0 && -d "$PROJECT_ROOT_DIR" ]]; then
		while IFS= read -r -d '' example; do
			EXAMPLE_FILES+=("$example")
		done < <(find "$PROJECT_ROOT_DIR" -type f -name '*.example' -print0 2>/dev/null)
	fi

	for EXAMPLE_FILE in "${EXAMPLE_FILES[@]+"${EXAMPLE_FILES[@]}"}"; do
		NEW_FILENAME="${EXAMPLE_FILE%.example}"
		ECHO_KEY_VALUE "$EXAMPLE_FILE   =>   " "$NEW_FILENAME"
		mv "${EXAMPLE_FILE}" "${NEW_FILENAME}"
	done
}

edit_file_gitignore() {
	if [[ -f "$PROJECT_ROOT_DIR/.gitignore" ]]; then
		GITIGNORE_EDITED=$(awk '/wp-docker/{print $1}' "$PROJECT_ROOT_DIR/.gitignore" | head -n 1)

		if [ "$GITIGNORE_EDITED" == '' ]; then
			EMPTY_LINE
			ECHO_YELLOW "eidt .gitignore file..."
			ex "$PROJECT_ROOT_DIR/.gitignore" <<EOF
1 insert
/wp-docker/
/logs/
/vendor/
adminer.php
wp-config-docker.php
.
xit
EOF
		fi
	else
		EMPTY_LINE
		ECHO_YELLOW "create .gitignore file..."
		cat <<-EOF >"$PROJECT_ROOT_DIR/.gitignore"
			/wp-docker/
			/logs/
			/vendor/
			adminer.php
			wp-config-docker.php
		EOF
	fi
}
