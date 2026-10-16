#!/bin/bash

TESTS_RUN=0
TESTS_FAILED=0

unit_fail() {
	local msg="${1:-assertion failed}"
	TESTS_FAILED=$((TESTS_FAILED + 1))
	echo "FAIL: $msg" >&2
	return 1
}

assert_eq() {
	local expected="$1"
	local actual="$2"
	local label="${3:-}"

	TESTS_RUN=$((TESTS_RUN + 1))
	if [[ "$expected" == "$actual" ]]; then
		return 0
	fi
	unit_fail "${label:+$label: }expected '$expected', got '$actual'"
}

assert_true() {
	local label="$1"
	shift

	TESTS_RUN=$((TESTS_RUN + 1))
	if "$@"; then
		return 0
	fi
	unit_fail "${label:+$label: }expected command to succeed"
}

assert_false() {
	local label="$1"
	shift

	TESTS_RUN=$((TESTS_RUN + 1))
	if ! "$@"; then
		return 0
	fi
	unit_fail "${label:+$label: }expected command to fail"
}

assert_version_lt() {
	local left="$1"
	local right="$2"
	local label="${3:-}"

	TESTS_RUN=$((TESTS_RUN + 1))
	if version_lt "$left" "$right"; then
		return 0
	fi
	unit_fail "${label:+$label: }expected version_lt $left $right"
}

assert_not_version_lt() {
	local left="$1"
	local right="$2"
	local label="${3:-}"

	TESTS_RUN=$((TESTS_RUN + 1))
	if ! version_lt "$left" "$right"; then
		return 0
	fi
	unit_fail "${label:+$label: }expected not version_lt $left $right"
}

unit_summary() {
	if [[ "$TESTS_FAILED" -eq 0 ]]; then
		echo "OK — $TESTS_RUN unit assertions passed"
		return 0
	fi

	echo "$TESTS_FAILED of $TESTS_RUN unit assertions failed" >&2
	return 1
}
