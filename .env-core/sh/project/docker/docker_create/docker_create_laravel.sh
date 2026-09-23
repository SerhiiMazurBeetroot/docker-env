#!/bin/bash

# shellcheck disable=SC1091
source "${ENV_DIR}/.env-core/sh/common.sh"

docker_create_laravel() {
	unset_variables
	docker_create_require_nginx || return 1
	get_domain_name
	check_domain_exists
	docker_create_require_new_site || return 1
	get_project_dir "$@"
	set_project_args
	check_data_before_continue_callback docker_create_laravel || return 1

	CREATE_TEMPLATE="laravel"
	docker_create_project docker_create_laravel_after
}

docker_create_laravel_after() {
	install_laravel || return 1
}

install_laravel() {
	local src="$PROJECT_ROOT_DIR/src"

	if [[ -f "$src/artisan" ]]; then
		ECHO_INFO "Laravel app already exists, skipping creation"
		return 0
	fi

	ECHO_INFO "Creating Laravel app..."
	mkdir -p "$src"
	find "$src" -mindepth 1 -delete

	local create_args=(create-project laravel/laravel . --no-interaction --prefer-dist)
	if [[ -n "${LARAVEL_VERSION:-}" ]]; then
		create_args=(create-project laravel/laravel . "$LARAVEL_VERSION" --no-interaction --prefer-dist)
	fi

	if ! docker run --rm \
		-u "$(id -u):$(id -g)" \
		-e COMPOSER_HOME=/tmp/composer \
		-v "$src":/app \
		-w /app \
		composer:2 \
		composer "${create_args[@]}"; then
		ECHO_ERROR "composer create-project failed"
		return 1
	fi

	if [[ ! -f "$src/artisan" ]]; then
		ECHO_ERROR "Laravel install did not create src/artisan"
		return 1
	fi

	laravel_configure_env "$src/.env" || return 1
	laravel_force_https "$src" || return 1
	laravel_install_login "$src" || return 1

	if [[ -d "$src/storage" ]]; then
		chmod -R a+rwX "$src/storage" "$src/bootstrap/cache" || true
	fi

	wait_for_db || return 1

	if ! docker exec -u "$(id -u):$(id -g)" "$DOCKER_CONTAINER_APP" php artisan migrate --force; then
		ECHO_ERROR "Laravel migrate failed"
		return 1
	fi

	laravel_seed_user || return 1

	ECHO_SUCCESS "Laravel app created in $src"
}

laravel_force_https() {
	local file="$1/app/Providers/AppServiceProvider.php"

	if [[ ! -f "$file" ]]; then
		ECHO_ERROR "AppServiceProvider not found: $file"
		return 1
	fi

	if grep -q 'URL::forceScheme' "$file"; then
		return 0
	fi

	python3 - "$file" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
old_use = "use Illuminate\\Support\\ServiceProvider;"
new_use = "use Illuminate\\Support\\Facades\\URL;\nuse Illuminate\\Support\\ServiceProvider;"
old_boot = """    public function boot(): void
    {
        //
    }"""
new_boot = """    public function boot(): void
    {
        if (str_starts_with((string) config('app.url'), 'https://')) {
            URL::forceScheme('https');
        }
    }"""
if old_use not in text or old_boot not in text:
    sys.exit("AppServiceProvider layout was not recognized")
path.write_text(text.replace(old_use, new_use, 1).replace(old_boot, new_boot, 1))
PY
}

laravel_install_login() {
	local src="$1"
	local uid gid

	uid="$(id -u)"
	gid="$(id -g)"

	ECHO_INFO "Installing Laravel Breeze login..."

	if ! docker run --rm \
		-u "${uid}:${gid}" \
		-e COMPOSER_HOME=/tmp/composer \
		-v "$src":/app \
		-w /app \
		composer:2 \
		composer require laravel/breeze --dev --no-interaction; then
		ECHO_ERROR "composer require laravel/breeze failed"
		return 1
	fi

	if ! docker exec -u "${uid}:${gid}" "$DOCKER_CONTAINER_APP" \
		php artisan breeze:install blade --no-interaction; then
		ECHO_ERROR "php artisan breeze:install failed"
		return 1
	fi

	if ! docker run --rm \
		-u "${uid}:${gid}" \
		-e HOME=/tmp \
		-v "$src":/app \
		-w /app \
		node:22-alpine \
		sh -c "npm install && npm run build"; then
		ECHO_ERROR "Laravel frontend build failed"
		return 1
	fi
}

laravel_env_set() {
	local file="$1"
	local key="$2"
	local value="$3"

	if grep -q "^${key}=" "$file"; then
		sed_inplace "s|^${key}=.*|${key}=${value}|" "$file"
	elif grep -q "^#[[:space:]]*${key}=" "$file"; then
		sed_inplace "s|^#[[:space:]]*${key}=.*|${key}=${value}|" "$file"
	else
		printf '%s=%s\n' "$key" "$value" >>"$file"
	fi
}

laravel_configure_env() {
	local file="$1"
	local db_name db_password

	if [[ ! -f "$file" ]]; then
		ECHO_ERROR "Laravel .env not found: $file"
		return 1
	fi

	db_name="$(env_file_value MYSQL_DATABASE || true)"
	db_password="$(env_file_value MYSQL_ROOT_PASSWORD || true)"
	[[ -n "$db_name" ]] || db_name="${DB_NAME:-laravel}"
	[[ -n "$db_password" ]] || db_password="PassWorD123"

	laravel_env_set "$file" APP_ENV "local"
	laravel_env_set "$file" APP_DEBUG "true"
	laravel_env_set "$file" APP_URL "https://${DOMAIN_FULL}"
	laravel_env_set "$file" DB_CONNECTION "mysql"
	laravel_env_set "$file" DB_HOST "${DOMAIN_NAME}-mysql"
	laravel_env_set "$file" DB_PORT "3306"
	laravel_env_set "$file" DB_DATABASE "$db_name"
	laravel_env_set "$file" DB_USERNAME "root"
	laravel_env_set "$file" DB_PASSWORD "$db_password"
	laravel_env_set "$file" MAIL_MAILER "smtp"
	laravel_env_set "$file" MAIL_HOST "${DOMAIN_NAME}-mail"
	laravel_env_set "$file" MAIL_PORT "1025"
	laravel_env_set "$file" MAIL_USERNAME "null"
	laravel_env_set "$file" MAIL_PASSWORD "null"
	laravel_env_set "$file" MAIL_ENCRYPTION "null"
	laravel_env_set "$file" LOGIN_EMAIL "developer@example.com"
	laravel_env_set "$file" LOGIN_PASSWORD "developer"
}

laravel_seed_user() {
	local email="developer@example.com"
	local password="developer"
	local name="Developer"

	if ! docker exec \
		-e HOME=/tmp \
		-e XDG_CONFIG_HOME=/tmp \
		-e LOGIN_EMAIL="$email" \
		-e LOGIN_PASSWORD="$password" \
		-e LOGIN_NAME="$name" \
		-u "$(id -u):$(id -g)" \
		"$DOCKER_CONTAINER_APP" \
		php artisan tinker --execute="App\\Models\\User::updateOrCreate(['email' => getenv('LOGIN_EMAIL')], ['name' => getenv('LOGIN_NAME'), 'password' => getenv('LOGIN_PASSWORD'), 'email_verified_at' => now()]);"; then
		ECHO_ERROR "Could not create the Laravel login user"
		return 1
	fi

	ECHO_SUCCESS "Laravel login: $email / $password"
}
