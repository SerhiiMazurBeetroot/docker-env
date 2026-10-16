# Tests

Two suites. They do not replace each other.

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

Add a case by sourcing the script with `unit_source "path/under/sh/file.sh"` and calling `assert_*`. Keep tests free of menus, `read`, and `docker`.

## ShellCheck

```bash
./.env-core/shellcheck.sh
```

Warning level, bash dialect. It scans `.env-core/sh`, `setup.sh`, and `.env-core/tests/unit`. It skips `sh/dev`. If `shellcheck` is not installed, the script runs the `koalaman/shellcheck` image.

CI (`.github/workflows/ci.yml`) runs both commands on push and pull request.

## Docker smokes

`sh/system/tests/` (`tests_actions`, `tests_new_projects`, `tests_helpers`) creates real sites. They need Nginx, images, and an interactive session. They load only in development mode from **System → Run tests**. Do not call them from the unit runner.
