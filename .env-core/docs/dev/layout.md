# Repository layout

`ENV_DIR` is the git clone. Everything the toolbox owns sits in `.env-core/`. Created sites sit next to it, one folder per host.

```
docker-env/
├── setup.sh                 entrypoint and docker-env alias target
├── wordpress/dev.blog.local/   a created site (not part of the toolbox)
└── .env-core/
    ├── sh/                  bash: core, menus, project, system
    ├── system/              nginx, nghost, ngrok compose stacks
    ├── data/                settings.log, instances.json (local, gitignored)
    ├── templates/           optional local project templates
    ├── webui/               Next.js dashboard
    ├── tests/unit/          fast shell unit tests
    ├── shellcheck.sh
    └── docs/                user guides and this developer section
```

## What each shell folder does

| Path | Loaded when |
| --- | --- |
| `sh/core/` | Every `./setup.sh` (autoloader) |
| `sh/menus/` | Every `./setup.sh` |
| `sh/project/` | First time a site action needs it (`load_project_modules`) |
| `sh/system/` | First time System / Web UI / healthcheck needs it (`load_system_modules`) |
| `sh/system/tests/` | **System → Run tests**, and only if `ENV_MODE=development` |
| `sh/dev/` | Never. Personal experiments. |

`common.sh` turns on `errexit` and `pipefail`. `nounset` starts after the autoloader finishes.

## Data files

| File | Role |
| --- | --- |
| `.env-core/data/settings.log` | `ENV_MODE`, `ENV_THEME`, `WEBUI_TOKEN`, git tokens |
| `.env-core/data/instances.json` | Sites the CLI and Web UI list |
| `.env-core/data/catalog.json` | Published versions for the create form (refreshed daily, see [catalog](catalog.md)) |
| `.env-core/data/catalog-refresh.log` | Log of that daily refresh |
| `.env-core/data/diagnostics.jsonl` | CLI errors, one JSON line each, tokens redacted (`record_diagnostic`) |
| `.env-core/data/webui-last-actions.json` | Last action result per site, shown on Web UI cards |
| `.env-core/system/nginx/.env` | Compose env for the proxy stack, including `WEBUI_TOKEN` |

`instances.json` is the source of truth for “which sites exist”. Docker state (running or stopped) is read from containers at list time.
