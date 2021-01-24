FROM php:7.4-fpm-alpine as webserver

# Install nginx & supervisor
RUN apk --no-cache add nginx supervisor && \
    rm /etc/nginx/conf.d/default.conf

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY config/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx && \
  chown -R nobody.nobody /var/www/html

# Install dependencies stage
FROM composer as composer

WORKDIR /var/www/html

COPY . .

RUN composer install --optimize-autoloader --no-interaction --no-progress

# Run application
FROM webserver as app

# Switch to use a non-root user from here on
USER nobody

WORKDIR /var/www/html

COPY --chown=nobody  --from=composer /var/www/html .

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

