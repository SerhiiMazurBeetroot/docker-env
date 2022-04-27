#!/bin/bash

# shellcheck disable=SC1091
FILE_SETTINGS='./env-core/settings.log'
FILE_INSTANCES='./wp-instances.log'

source ./env-core/sh/utils/colors.sh
source ./env-core/sh/utils/echo.sh
source ./env-core/sh/utils/helpers.sh

source ./env-core/sh/core/env-core-instances.sh
source ./env-core/sh/core/env-core-arguments.sh
source ./env-core/sh/core/env-core-setup.sh
source ./env-core/sh/core/env-core-options.sh
source ./env-core/sh/core/env-core-notice.sh
source ./env-core/sh/core/env-core-devenv.sh
source ./env-core/sh/core/env-core-legacy.sh

source ./env-core/sh/nginx/host.sh
source ./env-core/sh/nginx/setup-hosts-file.sh
source ./env-core/sh/nginx/docker-nginx.sh

source ./env-core/sh/wordpress/docker-wp.sh
source ./env-core/sh/wordpress/wp.sh

source ./env-core/sh/database/database.sh

source ./env-core/sh/git/env-git.sh
