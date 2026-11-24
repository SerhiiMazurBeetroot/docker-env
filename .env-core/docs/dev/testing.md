# Tests

Shell unit tests, Web UI tests and lint, and the Docker smokes. They do not replace each other.

## Unit tests

`.env-core/tests/unit/` exercises pure functions: hostname checks, `version_lt`, update-due dates, backup rotation, catalog lookups, archive filename parsing. No Docker.

```bash
./.env-core/tests/unit/run.sh
```

| File | Role |
| --- | --- |
| `bootstrap.sh` | Temp `DIR_DATA`, `TEST_RUNNING=1`, `unit_source` |
| `assert.sh` | `assert_eq`, `assert_true`, `assert_false`, summary |
| `run.sh` | Sources every `test_*.sh` and prints the summary |
| `test_*.sh` | One area each |

`bootstrap.sh` points `ENV_DIR` at the clone root (three levels above `tests/unit`). Assertions that expect a failure still print the script’s own error lines. That is normal.

A failed assertion does not stop the run. Every `test_*.sh` runs and the summary counts all failures. Sourced scripts load `common.sh`, which turns `errexit` back on, so `unit_source` and `run.sh` turn it off again. Keep that if you change either file.

Add a case by sourcing the script with `unit_source "path/under/sh/file.sh"` and calling `assert_*`. Keep tests free of menus, `read`, and `docker`.

A test that sets project globals (`PROJECT_DIR`, `DOMAIN_FULL`, `PROJECT_ROOT_DIR`) should clear them at the end, because every test file shares one shell. `test_site_root_guard.sh` is an example.

## ShellCheck

```bash
./.env-core/shellcheck.sh
```

Warning level, bash dialect. It scans `.env-core/sh`, `setup.sh`, and `.env-core/tests/unit`. It skips `sh/dev`. If `shellcheck` is not installed, the script runs the `koalaman/shellcheck` image.

CI (`.github/workflows/ci.yml`) runs both commands on push and pull request.

## Web UI tests and lint

From `.env-core/webui` (Node 24, the same major as the Web UI image):

```bash
npm ci
npm run lint
npm test
```

`npm test` runs `node --test` on `tests/**/*.test.mjs`. No browser, no Docker, no Next.js server. The suites cover:

| File | What it guards |
| --- | --- |
| `auth.test.mjs` | Token match, bearer/cookie, `settings.log` fallback, fail-closed without a token |
| `proxy.test.mjs` | `proxy.js`: 503 / login redirect without a token, 401 on a wrong token, public paths |
| `guards.test.mjs` | Domain, service, container, option and bulk-scope checks before `webui_cli.sh`; secret redaction |
| `updates.test.mjs` | Updates page sorting, summary, reading `updates.json` |
| `cli-output.test.mjs` | JSON and URL markers in CLI output, version choices |

`tests/helpers.mjs` gives each test a temp `ENV_DIR` and restores env vars. `tests/register.mjs` maps `next/server` to `next/server.js`, which plain Node ESM needs and the Next.js bundler does not.

`npm run lint` is ESLint 9 with `eslint-config-next` (`eslint.config.mjs`). ESLint stays on 9 until the plugins inside `eslint-config-next` support 10. `react-hooks/set-state-in-effect` is a warning for now: ten components still set state in an effect.

The CI `webui` job runs install, lint, tests and `npm run build`.

## Docker smokes

`sh/system/tests/` (`tests_actions`, `tests_new_projects`, `tests_helpers`) creates real sites. They need Nginx, images, and an interactive session. They load only in development mode from **System → Run tests**. Do not call them from the unit runner.
