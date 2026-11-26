#!/bin/bash

unit_source "core/available_projects.sh"
unit_source "core/wip_features.sh"

assert_true "updates is registered" wip_feature_registered "updates"
assert_false "unknown id is not registered" wip_feature_registered "not.a.feature"
# Creating projects from the Web UI is open to every user, so it is not a WIP feature.
assert_false "webui.create is not gated" wip_feature_registered "webui.create"

ENV_MODE=""
assert_false "updates is off without development" wip_feature "updates"

ENV_MODE="developments"
assert_false "typo does not enable updates" wip_feature "updates"

ENV_MODE="development"
assert_true "updates is on in development" wip_feature "updates"
assert_false "unknown id stays off in development" wip_feature "not.a.feature"
