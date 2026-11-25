#!/bin/bash

# "Site already exists" is about the name being typed, not about the existing site.
# ECHO_ERROR records an error as a notice for $DOMAIN_NAME, so the clash must be
# reported without it; otherwise the existing site's Web UI card shows the error.

unit_source "core/utils/colors.sh"
unit_source "core/utils/echo.sh"

record_diagnostic() {
	RECORDED_MESSAGE="$1"
	RECORDED_TARGET="${3-unset}"
}

RECORDED_MESSAGE=""
RECORDED_TARGET="unset"
DOMAIN_NAME="test-wp"
echo_site_exists >/dev/null

assert_eq "Site test-wp already exists" "$RECORDED_MESSAGE" "the message names the taken site"
assert_eq "" "$RECORDED_TARGET" "the error is not attached to the existing site"
assert_eq "test-wp" "$DOMAIN_NAME" "DOMAIN_NAME is unchanged afterwards"

unset -f record_diagnostic
unset DOMAIN_NAME RECORDED_MESSAGE RECORDED_TARGET
