#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

# Match catalog ids longest-first so "wordpress_nextjs" wins over "wordpress".
_project_ids_longest_first() {
	local i j tmp
	local -a ids=("${PROJECT_IDS[@]}")

	for ((i = 0; i < ${#ids[@]}; i++)); do
		for ((j = i + 1; j < ${#ids[@]}; j++)); do
			if ((${#ids[$j]} > ${#ids[$i]})); then
				tmp=${ids[$i]}
				ids[$i]=${ids[$j]}
				ids[$j]=$tmp
			fi
		done
	done

	printf '%s\n' "${ids[@]}"
}

# archive_<type>_<domain_full>_<dd-mm-yy>.zip (see zip_project.sh).
project_archive_parse_zip() {
	local file="${1:-}"
	local base inner type

	FILENAME="$file"
	base=$(basename "$file")

	if [[ ! "$base" =~ ^archive_(.+)_([0-9]{2}-[0-9]{2}-[0-9]{2})\.zip$ ]]; then
		ECHO_ERROR "Unrecognized archive filename: $base"
		ECHO_INFO "Expected: archive_<type>_<domain>_<dd-mm-yy>.zip"
		return 1
	fi

	inner="${BASH_REMATCH[1]}"
	PROJECT_TYPE=""
	DOMAIN_FULL=""

	while IFS= read -r type; do
		[[ -n "$type" ]] || continue
		if [[ "$inner" == "${type}_"* ]]; then
			PROJECT_TYPE="$type"
			DOMAIN_FULL="${inner#${type}_}"
			break
		fi
	done < <(_project_ids_longest_first)

	if [[ -z "$PROJECT_TYPE" || -z "$DOMAIN_FULL" ]]; then
		ECHO_ERROR "Could not read project type from archive: $base"
		return 1
	fi

	export PROJECT_TYPE

	DOMAIN_NAME=$(instances_get domain_name "$DOMAIN_FULL" domain_full)
	if [[ -z "${DOMAIN_NAME:-}" ]]; then
		DOMAIN_NAME="${DOMAIN_FULL%%.*}"
	fi

	return 0
}

get_archived_projects() {
	ZIP_FILES=()
	while IFS= read -r zip; do
		[[ -n "$zip" ]] && ZIP_FILES+=("$zip")
	done < <(find "${ENV_DIR:-.}" -type f -name "archive_*.zip" 2>/dev/null)

	if [[ ${#ZIP_FILES[@]} -eq 0 ]]; then
		ECHO_YELLOW "No archive_*.zip files under ${ENV_DIR:-.}"
		return 1
	fi

	if [[ ${#ZIP_FILES[@]} -gt 0 ]]; then
		while true; do
			EMPTY_LINE
			ECHO_CYAN "======== UNZIP project ======="
			ECHO_YELLOW "[0] Return to the previous menu"

			print_list "${ZIP_FILES[@]}"

			choice=$(GET_USER_INPUT "select_one_of")

			[ -z "$choice" ] && choice=-1
			if (("$choice" > 0 && "$choice" <= ${#ZIP_FILES[@]})); then
				if ! project_archive_parse_zip "${ZIP_FILES[$(($choice - 1))]}"; then
					continue
				fi

				if ! get_project_dir "skip_question"; then
					continue
				fi
				break
			else
				if [ "$choice" == 0 ]; then
					return 1
				else
					ECHO_WARN_RED "Wrong option"
				fi
			fi
		done
	fi
}
