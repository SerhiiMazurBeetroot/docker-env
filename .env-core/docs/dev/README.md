# Developer guide

These pages are for changing docker-env itself. Day-to-day site setup stays in the [user docs](../README.md).

| Page | What it covers |
| --- | --- |
| [Repository layout](layout.md) | Where code, data, and sites live |
| [Shell and menus](shell.md) | CLI startup, function names (`webui_*` vs `_diagnostic_unlock`), menu loop |
| [Project catalog](catalog.md) | Adding a project type for CLI and Web UI |
| [Tests](testing.md) | Unit tests, ShellCheck, Docker smokes |
| [Updates check](updates.md) | Pinned images, Node, npm packages and releases vs newest (Web UI `/updates`) |

WIP product behavior uses the same switch. Add an id to [`sh/core/wip_features.ids`](../../sh/core/wip_features.ids), then guard the shell with `wip_feature "<id>"` and the Web UI with `wipFeatureEnabled("<id>")` from `webui/lib/features.js`. The dashboard snapshot includes a `features` map. `webui.create` is the Create button and `POST /api/projects`; both stay off unless `ENV_MODE=development`.

WIP project types stay out of the user guides. Their pages:

- [Laravel](../projects/laravel.md)
- [Directus + Next.js](../projects/directus-nextjs.md)
- [WordPress + Next.js](../projects/wordpress-nextjs.md)
- [Node.js API](../projects/nodejs-api.md)

## Conventions

- Target **bash 3.2** (macOS default). No associative arrays.
- `ENV_DIR` is the clone root. Scripts live under `.env-core/`.
- Do not commit `.env-core/data/settings.log`, tokens, or site dumps.
- `sh/dev/` is local scratch and is not sourced. See [sh/dev/README.md](../../sh/dev/README.md).

## Docs media

`docs/gifs/` are terminal recordings used in the user guides. `docs/yml/` holds the matching recorder configs (one `.yml` per GIF, same name). Re-record a GIF when the menu it shows changes. All seven were recorded before the main menu was renamed and still show **New project** instead of **2 New site**.

## Quick checks

From the clone root:

```bash
./.env-core/shellcheck.sh
./.env-core/tests/unit/run.sh
./setup.sh catalog --json
(cd .env-core/webui && npm run lint && npm test)
```

GitHub Actions runs ShellCheck, the shell unit suite, and Web UI lint, tests and build (`.github/workflows/ci.yml`). The Docker smoke tests under `sh/system/tests/` stay manual and only appear in the CLI when `ENV_MODE=development`.
