# Project catalog

One row in `sh/core/available_projects.sh` is the project type. Every `PROJECT_*` array shares the same index. Bash 3.2 has no associative arrays, so lookups are `project_index` / `project_field`.

Stable rows (`PROJECT_TIERS=stable`) always show in **New site**. `wip` rows show only when `ENV_MODE=development`.

## Columns that matter for create

| Array | Meaning |
| --- | --- |
| `PROJECT_IDS` | Type id (`wordpress`, `nodejs_api`, …) |
| `PROJECT_MENU_TITLES` | Label in **New site** |
| `PROJECT_SETUP_FLOWS` | `installation_type` (WordPress/Bedrock) or `domain` |
| `PROJECT_SETUP_ARGS` | Whether the domain flow calls `set_project_args` |
| `PROJECT_DIR_QUESTIONS` | Extra prompts before compose is written |
| `PROJECT_CREATE_FLAGS` | Switches for `docker_create_dispatch` |
| `PROJECT_AFTER_HOOKS` | Function name in `docker_create/<type>.sh`, or empty |

The Web UI does not keep its own type list. `./setup.sh catalog --json` prints the visible rows (`project_catalog_emit_json`). `webui/lib/catalog.js` reads that output.

Published PHP, WordPress, Laravel, Node, Next.js, Directus, and Elasticsearch releases live in `.env-core/data/catalog.json`. The create form and `version_catalog_reject_unknown` both read that file. `wordpressPhp` lists the PHP versions that have an official `wordpress:<wp>-php<php>-apache` image. Empty still means the live default.

The Web UI container runs `catalog_refresh.sh loop` in the background. Once a day it rewrites `.env-core/data/catalog.json` from the public release feeds and records `updated`. If a feed is unreachable, the previous file stays. The log is `.env-core/data/catalog-refresh.log`.

## Adding a type

1. Append one value to every `PROJECT_*` array in `available_projects.sh` (same position).
2. If the type needs a post-create step, add `docker_create_<id>.sh` and set `PROJECT_AFTER_HOOKS`.
3. Add a template under `templates/<id>/` or document the GitHub template repo. `CREATE_TEMPLATE_SOURCE=local` copies the local template.
4. Add a short user page under `docs/projects/` and link it from [docs/README.md](../README.md).
5. Cover catalog lookups in `tests/unit/test_catalog.sh` if you add a new helper.

`docker_create_dispatch` is the only create entry. Do not add a new top-level `docker_create_<id>.sh` wrapper.
