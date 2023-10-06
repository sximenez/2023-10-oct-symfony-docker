# Adjust version to need
FROM php:8.2-fpm-alpine

# Adjust variables
ENV PHPUSER=symfony
ENV PHPGROUP=symfony

ENV UID=1000
ENV GID=1000

RUN addgroup -g 1006 --system symfony
RUN adduser -G www-data --system -D -s /bin/sh -u 1006 symfony

RUN mkdir -p /var/www/html/public

RUN docker-php-ext-install pdo pdo_mysql

CMD ["php-fpm"]