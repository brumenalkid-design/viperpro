FROM php:8.2-apache

RUN apt-get update && apt-get install -y libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath
RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# DELETE ANY EXISTING CACHE FILES BEFORE BOOT
RUN rm -f bootstrap/cache/*.php
RUN mkdir -p storage/logs storage/framework/sessions storage/framework/views storage/framework/cache/data bootstrap/cache
RUN chmod -R 777 storage bootstrap/cache
RUN chown -R www-data:www-data storage bootstrap/cache

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# BOOT SCRIPT - NO MERCY
RUN echo '#!/bin/sh\n\
# CLEAN FILESYSTEM CACHE\n\
rm -f bootstrap/cache/config.php\n\
rm -f bootstrap/cache/services.php\n\
\n\
# DATABASE RECONSTRUCTION\n\
export PGPASSWORD=$DB_PASSWORD\n\
psql -h $DB_HOST -U $DB_USERNAME -d $DB_DATABASE -p $DB_PORT -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"\n\
psql -h $DB_HOST -U $DB_USERNAME -d $DB_DATABASE -p $DB_PORT -f /var/www/html/sql/viperpro.1.6.1.sql\n\
\n\
apache2-foreground' > /usr/local/bin/deploy.sh

RUN chmod +x /usr/local/bin/deploy.sh
ENTRYPOINT ["deploy.sh"]
