#!/bin/bash

unit_source "core/core_system_check.sh"

settings_file="$UNIT_TMP/settings_get.log"
cat >"$settings_file" <<'SETTINGS'
# ENV_MODE=development is how you turn on dev mode
OLD_ENV_MODE=development
ENV_MODE=
ENV_THEME=dark
ENV_THEME=light
ENV_VERSION=abc123 trailing
ENV_DATE_CHECK=11/17/2026
SETTINGS
printf 'WEBUI_TOKEN=tok\r\n' >>"$settings_file"

assert_eq "" "$(settings_get ENV_MODE "$settings_file")" "comment and other keys do not set ENV_MODE"
assert_eq "dark" "$(settings_get ENV_THEME "$settings_file")" "first line wins"
assert_eq "abc123" "$(settings_get ENV_VERSION "$settings_file")" "value stops at the first space"
assert_eq "11/17/2026" "$(settings_get ENV_DATE_CHECK "$settings_file")" "slashes are kept"
assert_eq "tok" "$(settings_get WEBUI_TOKEN "$settings_file")" "CRLF line ending is stripped"
assert_eq "" "$(settings_get MISSING "$settings_file")" "missing key is empty"
assert_eq "" "$(settings_get ENV_MODE "$UNIT_TMP/no-such-file")" "missing file is empty"

saved_settings="$FILE_SETTINGS"
FILE_SETTINGS="$settings_file"
env_mode >/dev/null
assert_eq "" "$ENV_MODE" "env_mode ignores a commented ENV_MODE line"
FILE_SETTINGS="$saved_settings"
ENV_MODE=""
