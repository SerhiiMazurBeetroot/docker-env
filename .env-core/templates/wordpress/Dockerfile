FROM wordpress:{WP_VERSION}-php{PHP_VERSION}-apache

#Add sudo in order to run wp-cli as the www-data user 
RUN apt-get -y update
RUN apt-get install -y sudo

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Get latest Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php

#Add WP-CLI 
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp-cli.phar && \
    echo '#!/bin/sh' >> /usr/local/bin/wp && \
    echo 'wp-cli.phar "$@" --allow-root' >> /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

# Set working directory
WORKDIR /var/www/html/
RUN chown -R www-data:www-data .