FROM php:8.2-apache

RUN apt-get update && apt-get install -y libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath
RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# Permissões e limpeza de cache físico
RUN rm -rf bootstrap/cache/*.php && mkdir -p bootstrap/cache && chmod -R 777 storage bootstrap/cache && chown -R www-data:www-data /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# Script de boot com tolerância a falhas no psql
RUN echo '#!/bin/sh\n\
php artisan config:clear\n\
php artisan cache:clear\n\
\n\
export PGPASSWORD=$DB_PASSWORD\n\
psql -h $DB_HOST -U $DB_USERNAME -d $DB_DATABASE -p $DB_PORT -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" || true\n\
psql -h $DB_HOST -U $DB_USERNAME -d $DB_DATABASE -p $DB_PORT -f /var/www/html/sql/viperpro.1.6.1.sql || true\n\
\n\
apache2-foreground' > /usr/local/bin/deploy.sh

RUN chmod +x /usr/local/bin/deploy.sh
ENTRYPOINT ["deploy.sh"]
