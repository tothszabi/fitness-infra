FROM wordpress:6.9-php8.2-fpm-alpine

# Upgrade all Alpine packages to pick up OS-level security patches
# (base image may lag behind latest Alpine security advisories)
RUN apk upgrade --no-cache

# Install Redis extension
RUN apk add --no-cache pcre-dev fcgi $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del $PHPIZE_DEPS

# Copy custom tuning
COPY custom.ini /usr/local/etc/php/conf.d/custom.ini
COPY fpm-tuning.conf /usr/local/etc/php-fpm.d/zz-tuning.conf
