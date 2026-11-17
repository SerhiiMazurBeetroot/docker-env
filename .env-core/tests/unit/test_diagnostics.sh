#!/bin/bash

unit_source "core/diagnostics.sh"
unit_source "core/core_system_check.sh"

assert_true "empty mode is accepted" env_mode_accepted ""
assert_true "development is accepted" env_mode_accepted "development"
assert_false "typo is rejected" env_mode_accepted "developments"

TEST_RUNNING=0
DOMAIN_NAME=""
record_diagnostic "Could not start nginx" "start" "blog" "WEBUI_TOKEN=secret"
record_diagnostic "Could not start nginx" "start" "blog" "again"

count=$(grep -c 'Could not start nginx' "$DIR_DATA/diagnostics.jsonl" || true)
assert_eq "1" "$count" "duplicate cli error is stored once"

if grep -q 'secret' "$DIR_DATA/diagnostics.jsonl"; then
	assert_eq "redacted" "present" "token leaked into diagnostics"
else
	assert_eq "redacted" "redacted" "token redacted"
fi

notice=$(jq -r '.blog.ok' "$DIR_DATA/webui-last-actions.json")
assert_eq "false" "$notice" "site notice records the failure"

clear_site_notice "blog" "start"
notice=$(jq -r '.blog.ok' "$DIR_DATA/webui-last-actions.json")
assert_eq "true" "$notice" "success clears the site failure"

message=$(jq -r '.blog.message' "$DIR_DATA/webui-last-actions.json")
assert_eq "" "$message" "cleared notice has no message"

DOMAIN_NAME=hooksite
ECHO_ERROR "hook failure" >/dev/null
DOMAIN_NAME=""
hook=$(jq -r '.hooksite.message' "$DIR_DATA/webui-last-actions.json")
assert_eq "hook failure" "$hook" "ECHO_ERROR stores the site failure"

printf 'ENV_MODE="development"\n' >"$FILE_SETTINGS"
ENV_MODE_WARNED=0
env_mode >/dev/null
assert_eq "development" "$ENV_MODE" "quoted development is accepted"

printf 'ENV_MODE=developments\n' >"$FILE_SETTINGS"
before=$(wc -l <"$DIR_DATA/diagnostics.jsonl" | tr -d ' ')
warn=$(env_mode)
after=$(wc -l <"$DIR_DATA/diagnostics.jsonl" | tr -d ' ')
assert_eq "$before" "$after" "unknown ENV_MODE stays out of the bug log"
# The unknown-mode warning is silenced in env_mode (core_system_check.sh).
assert_eq "" "$warn" "unknown ENV_MODE prints no warning"
TEST_RUNNING=1
