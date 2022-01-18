#!/bin/bash

# shellcheck disable=SC1091
source ./env-core/sh/utils/colors.sh
source ./env-core/sh/utils/echo.sh
source ./env-core/sh/utils/helpers.sh
source ./env-core/sh/utils/dev-env.sh

source ./env-core/sh/core/env-core-instances.sh
source ./env-core/sh/core/env-core-arguments.sh
source ./env-core/sh/core/env-core-setup.sh

source ./env-core/sh/nginx/host.sh
source ./env-core/sh/nginx/setup-hosts-file.sh
source ./env-core/sh/nginx/docker-nginx.sh

source ./env-core/sh/wordpress/docker-wp.sh
source ./env-core/sh/wordpress/wp.sh

source ./env-core/sh/database/database.sh
