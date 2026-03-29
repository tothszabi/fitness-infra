FROM wordpress:8.2-fpm-alpine

# Install Redis extension
RUN apk add --no-cache pcre-dev $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del $PHPIZE_DEPS

# Copy custom tuning
COPY custom.ini /usr/local/etc/php/conf.d/custom.ini
COPY fpm-tuning.conf /usr/local/etc/php-fpm.d/zz-tuning.conf
