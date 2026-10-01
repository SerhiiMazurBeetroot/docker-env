#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

wp_composer_install() {
	if [ "$DOMAIN_NAME" == '' ]; then
		running_projects_list "======= Install Composer ======" || return 1
		get_db_name
		wp_get_default_theme
		edit_file_env_setup_beetroot
		edit_file_gitignore
	fi

	if [[ -f "$PROJECT_WP_CONTENT_DIR/themes/$WP_DEFAULT_THEME/composer.json" ]]; then
		EMPTY_LINE
		ECHO_YELLOW "Running composer install... $DOCKER_CONTAINER_APP"

		COMPOSER_ISSUE=$(wp_composer_in_theme | awk '{if(/allowed/) print }' || true)
		ECHO_YELLOW "COMPOSER_ISSUE: $COMPOSER_ISSUE"

		WP_COMPOSER_CLEAN=1 wp_composer_in_theme || true
	else
		ECHO_YELLOW "composer.json file doesn't exists"
	fi
}

wp_composer_package() {
	EMPTY_LINE
	ECHO_KEY_VALUE "Package example: " '"wpackagist-plugin/safe-svg": "^2.0"'
	EMPTY_LINE
	read -rp "$(ECHO_YELLOW "Please fill in the package:")" package

	while [ -z "$package" ]; do
		read -rp "$(ECHO_YELLOW "Please fill in the package: ")" package
	done

	if [ "$DOMAIN_NAME" == '' ]; then
		running_projects_list "======= Install package ======" || return 1
		get_db_name
		wp_get_default_theme
	fi

	if [[ ! "$package" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*\/[A-Za-z0-9][A-Za-z0-9._-]*(:[A-Za-z0-9._*^~<>=|@ -]+)?$ ]]; then
		ECHO_ERROR "Invalid composer package"
		return 1
	fi

	docker exec -i \
		-e WP_THEME="${WP_DEFAULT_THEME}" \
		-e WP_PACKAGE="$package" \
		"$DOCKER_CONTAINER_APP" \
		bash -lc 'cd "./wp-content/themes/$WP_THEME" && composer require -- "$WP_PACKAGE"' || true
}

wp_composer_in_theme() {
	docker exec -i \
		-e WP_THEME="${WP_DEFAULT_THEME}" \
		-e WP_COMPOSER_CLEAN="${WP_COMPOSER_CLEAN:-}" \
		"$DOCKER_CONTAINER_APP" \
		bash -lc 'cd "./wp-content/themes/$WP_THEME" && if [ "$WP_COMPOSER_CLEAN" = 1 ]; then rm -rf ./vendor; fi && composer install'
}

wp_get_default_theme() {
	if [[ -d "$PROJECT_DATABASE_DIR" ]]; then
		# DB_FILE
		get_db_file

		if [[ -f "$PROJECT_DATABASE_DIR/$DB_FILE" ]]; then
			#1 => find in file | #2 => replace 'stylesheet' | #3 => replace character '' | #4 => replace , | #5 => replace space
			WP_DEFAULT_THEME=$(grep -o "'stylesheet',\s*'[A-Za-z0-9.,-]*\+'" "$PROJECT_DATABASE_DIR/$DB_FILE" | sed 's/'stylesheet'//g' | sed 's/'\''//g' | sed 's/,//g' | sed 's/^[ \t]*//;s/[ \t]*$//')

			# Replace variable WP_DEFAULT_THEME .env file
			PREV_THEME="$(grep -o "WP_DEFAULT_THEME=[A-Za-z0-9.,-]*\+" "$PROJECT_DOCKER_DIR"/.env)"
			sed_inplace "s~${PREV_THEME}~WP_DEFAULT_THEME=${WP_DEFAULT_THEME}~g" "$PROJECT_DOCKER_DIR/.env"

		else
			ECHO_YELLOW "DB FILE doesn't exists"
		fi
	else
		ECHO_ERROR "DB DIR doesn't exists"
	fi
}

wp_npm_install() {
	if [ "$DOMAIN_NAME" == '' ]; then
		running_projects_list "======= Install npm ======" || return 1
		wp_get_default_theme
	fi

	if [[ -f "$PROJECT_WP_CONTENT_DIR/themes/$WP_DEFAULT_THEME/package.json" ]]; then
		EMPTY_LINE
		ECHO_YELLOW "Running npm install... $DOCKER_CONTAINER_APP"
		docker exec -i \
			-e WP_THEME="${WP_DEFAULT_THEME}" \
			"$DOCKER_CONTAINER_APP" \
			bash -lc 'cd "./wp-content/themes/$WP_THEME" && rm -rf ./node_modules && npm install' || true
	fi
}

wait_for_wp_core() {
	local marker="/var/www/html/wp-includes/version.php"

	if [[ "${PROJECT_TYPE:-}" == "bedrock" ]]; then
		marker="/var/www/html/web/wp/wp-includes/version.php"
	fi

	EMPTY_LINE
	ECHO_YELLOW "Waiting for WordPress core at $marker"

	docker exec -i -e WP_MARKER="$marker" "$DOCKER_CONTAINER_APP" sh -c '
		i=0
		until [ -f "$WP_MARKER" ]; do
			i=$((i + 1))
			if [ "$i" -gt 120 ]; then
				echo "Timeout waiting for WordPress files ($WP_MARKER)" >&2
				exit 1
			fi
			echo "WordPress files not ready yet..." >&2
			sleep 2
		done
	'
}

wp_core_install_exec() {
	local command="$1"

	case "$command" in
	install | multisite-install) ;;
	*)
		ECHO_ERROR "Unknown wp core command"
		return 1
		;;
	esac

	docker exec -i \
		-e WP_INSTALL_COMMAND="$command" \
		-e WP_INSTALL_URL="https://${DOMAIN_FULL}" \
		-e WP_INSTALL_TITLE="${DOMAIN_NAME}" \
		-e WP_INSTALL_USER="${WP_USER}" \
		-e WP_INSTALL_PASSWORD="${WP_PASSWORD}" \
		"$DOCKER_CONTAINER_APP" \
		sh -c 'wp core "$WP_INSTALL_COMMAND" --url="$WP_INSTALL_URL" --title="$WP_INSTALL_TITLE" --admin_user="$WP_INSTALL_USER" --admin_password="$WP_INSTALL_PASSWORD" --admin_email=example@example.com --skip-email --allow-root'
}

wp_core_install() {
	wait_for_wp_core || return 1

	ECHO_WARN_YELLOW "wp_core_install..."
	if [[ "${MULTISITE:-}" == "yes" || "${MULTISITE:-}" == "2" ]]; then
		wp_core_install_exec "multisite-install"
		wp_multisite_htaccess
	else
		wp_core_install_exec "install"
	fi

	ECHO_SUCCESS "Done!"
}
