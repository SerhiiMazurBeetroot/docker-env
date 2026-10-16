#!/bin/bash

unit_source "core/env_settings/core_env_settings.sh"

today=$(date +'%m/%d/%Y')
yesterday=$(date -v-1d +'%m/%d/%Y' 2>/dev/null || date -d 'yesterday' +'%m/%d/%Y')

printf 'ENV_DATE_CHECK=%s\n' "$yesterday" >"$FILE_SETTINGS"
assert_true "missing today means due" env_updates_due

printf 'ENV_DATE_CHECK=%s\n' "$today" >"$FILE_SETTINGS"
assert_false "same day not due" env_updates_due

rm -f "$FILE_SETTINGS"
assert_true "no settings file means due" env_updates_due
