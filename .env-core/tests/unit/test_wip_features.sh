#!/bin/bash

unit_source "core/available_projects.sh"
unit_source "core/wip_features.sh"

assert_true "webui.create is registered" wip_feature_registered "webui.create"
assert_false "unknown id is not registered" wip_feature_registered "not.a.feature"

ENV_MODE=""
assert_false "create is off without development" wip_feature "webui.create"

ENV_MODE="developments"
assert_false "typo does not enable create" wip_feature "webui.create"

ENV_MODE="development"
assert_true "create is on in development" wip_feature "webui.create"
assert_false "unknown id stays off in development" wip_feature "not.a.feature"
