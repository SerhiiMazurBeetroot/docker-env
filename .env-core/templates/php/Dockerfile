# default version if empty
ARG PHP_VERSION=8.2

FROM php:${PHP_VERSION}-apache

# Get latest Composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && rm composer-setup.php

RUN docker-php-ext-install mysqli
