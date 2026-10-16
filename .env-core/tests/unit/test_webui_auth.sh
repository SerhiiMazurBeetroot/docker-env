#!/bin/bash

unit_source "system/webui/webui_common.sh"
unit_source "system/webui/webui_auth.sh"

printf '%s\n' 'WEBUI_TOKEN=unit-token-value' >"$FILE_SETTINGS"

shown=$(webui_show_token)
assert_true "menu token printer includes the saved token" grep -q 'unit-token-value' <<<"$shown"
assert_true "menu token printer names the field" grep -q 'WEBUI_TOKEN' <<<"$shown"

printf '%s\n' 'ENV_MODE=development' >"$FILE_SETTINGS"
missing=$(webui_read_token)
assert_eq "" "$missing" "missing token stays empty"
