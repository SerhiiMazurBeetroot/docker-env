FROM wordpress:{WP_VERSION}-php{PHP_VERSION}-apache

# Install system dependencies
# Add sudo in order to run wp-cli as the www-data user 
RUN apt-get -y update && apt-get install -y sudo --no-install-recommends \
    git \
    curl \
    libfreetype6-dev \
    libicu-dev \
    libjpeg-dev \
    libmagickwand-dev \
    libpng-dev \
    libwebp-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip

RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp

# Install PHP extensions
RUN docker-php-ext-install -j "$(nproc)" \
    bcmath \
    exif \
    gd \
    intl \
    mysqli \
    zip

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

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