# Shell and menus

How the CLI is structured, and how to name a new function. Bash has one global namespace after a file is sourced, so the name is the only privacy the script has.

## Startup

`setup.sh` sets `CORE_VERSION` and `ENV_DIR`, sources `sh/autoloader.sh`, then either:

- `cli_dispatch` when arguments are present (`create`, `catalog --json`)
- `main_actions` when there are none: healthcheck, startup logo, `primary_menu`

The autoloader sources every `*.sh` under `sh/core` and `sh/menus`. Project and system scripts stay unloaded until `load_project_modules` or `load_system_modules`.

Two ways in:

| Invocation | What runs |
| --- | --- |
| `./setup.sh` with no arguments | `main_actions` → healthcheck, logo, `primary_menu` |
| `./setup.sh create …` or `./setup.sh catalog --json` | `cli_dispatch` in `sh/core/cli.sh` |

`primary_menu` is **0 Exit**, **1 System**, **2 New site**, **3 Sites**, **4 Helpers**. A menu calls another `*_menu` or a public function. It does not contain the work itself.

## How functions are named

Every sourced function is visible to every other file. There is no `private` keyword. The name says who may call it.

**Public name:** `area_action`, with no leading underscore. Menus, the Web UI, and other files call this.

| Prefix | Used for |
| --- | --- |
| `cli_` | Argument commands (`cli_dispatch`, `cli_create`, `cli_catalog`) |
| `*_menu` | One interactive screen (`webui_menu`, `system_menu`, `primary_menu`) |
| `webui_` | Web UI server, auth, list, project actions |
| `docker_` / `nginx_` / `setup_` | That area’s steps |
| `project_` / `instances_` | Catalog and the site list |

**Helper name:** a leading underscore, then the same area. `_diagnostic_unlock` is only for `diagnostics.sh`. `record_diagnostic` is the function other files call. The underscore does not hide it from Bash. It tells the next reader to leave it alone.

Same pattern elsewhere:

| Helper | Called from |
| --- | --- |
| `_diagnostic_lock`, `_diagnostic_unlock`, `_diagnostic_redact` | `record_diagnostic` only |
| `_hosts_has_token`, `_hosts_append_line` | `setup_hosts_file` only |
| `_instances_write` | the `instances_*` functions in that file |
| `_env_boot_mode` | `load_system_modules` only |
| `_project_catalog_split` | the bottom of `available_projects.sh`, once, at source time |

If a second file needs the helper, drop the underscore and keep the area prefix. `webui_hosts_path` is shared by the Web UI scripts, so it has no underscore.

A new function in `webui_auth.sh` that only `webui_show_token` uses would be `_webui_token_line`. A function a menu item calls would be `webui_show_token`.

## What a function looks like

One area per file. The file sources `common.sh`, defines helpers, then defines the public function. Do not run work at source time. The catalog split at the bottom of `available_projects.sh` is the exception: those arrays must exist as soon as the file loads.

```bash
# File-local helper. The leading _ means other files do not call it.
_diagnostic_unlock() {
	local lock="$1"
	rmdir "$lock" 2>/dev/null || true
}

# Public. Menus and the Web UI call this name.
# record_diagnostic MESSAGE [ACTION] [TARGET] [DETAIL]
record_diagnostic() {
	local lock="${DIR_DATA}/diagnostics.jsonl.lock"
	_diagnostic_lock "$lock" || return 0
	_diagnostic_unlock "$lock"
	return 0
}
```

Inside the function:

- `local` for every temporary. Project state that later steps read (`DOMAIN_FULL`, `PROJECT_TYPE`, `HOST_EXTRA`) stays global on purpose.
- `return 0` or `return 1`. `exit` ends the whole process, so the menu the user is in goes away with it. A new function returns. `primary_menu` uses `exit` only for **0 Exit**.
- Talk to the user with `ECHO_SUCCESS`, `ECHO_ERROR`, `ECHO_INFO`, `ECHO_KEY_VALUE` from `sh/core/utils/echo.sh`. Those lines are for a person at the prompt.
- Return a value with `printf '%s'`. Callers capture that with `token=$(webui_read_token)`. A captured function must not `ECHO_*`, or the colors and labels become part of the value.
- Read arguments as `"${1:-}"`. When the shape is not obvious, put a comment on the line above the function, as `record_diagnostic` does.
- `${NAME:-}` for an optional variable. `nounset` is on after the autoloader finishes, so a bare `$MISSING` aborts the script.
- Target bash 3.2. No associative arrays and no namerefs. A lookup table is parallel arrays plus an index function (`project_index` / `project_field`).

`if ! some_function; then` turns off `errexit` for the whole body of `some_function`. A failure inside it will not stop the function. Check the important command there yourself, or write `some_function || return 1` at the call site when that call is not already inside an `if`.

`GET_USER_INPUT` is the only prompt. With `CLI_NONINTERACTIVE=1` or `TEST_RUNNING=1` it returns the default and does not `read`. That is how `./setup.sh create` and the unit tests skip menus.

## Menus

Each menu is a `while true` loop in `sh/menus/`. **`[0]` returns** to the caller (`return 0`). The main menu’s `[0]` is the exception: it `exit`s.

The `case` arm calls one public function (`webui_server_start`, `webui_show_token`). An item that exists only in development is a higher number, and the `case` arm checks `ENV_MODE` again so typing that number in normal mode is an invalid selection.

`primary_menu` draws the logo with `env_logo_draw`. `env_logo_startup` plays the animation once and skips the next draw so the first menu does not print the logo twice.

## Create path

**New site** does not call a different script per type anymore. `docker_create_dispatch` reads the catalog row for that type (`PROJECT_SETUP_FLOWS`, questions, flags, after-hooks) and runs one pipeline.

Per-type files under `sh/project/docker/docker_create/` are after-hooks (WordPress, Bedrock, Next.js, Laravel, Elastic, Directus+Next, WordPress+Next). Types without extra steps have no file there.

Non-interactive create:

```bash
./setup.sh create --type wordpress --name blog --domain dev.blog.local
```

## Ngrok

`sh/system/ngrok/ngrok_docker.sh` and `.env-core/system/ngrok/` still exist. `ngrok_menu` is not linked from **System**, and the per-site “add endpoint” action is commented out. Treat it as unused until those menus are wired again. Do not document it as a user feature.

## Web UI bridge

The dashboard does not talk to Docker itself. API routes call `webui/webui_cli.sh`, which sources the same shell functions as the CLI (`list`, `create`, start/stop). Auth is `WEBUI_TOKEN` in `settings.log`, copied into the nginx compose env, checked by `webui/proxy.js` (Next.js 16 proxy, formerly middleware). The CLI prints that token from **1 System → 2 Web UI → 4 Show sign-in token** (`webui_show_token`).
