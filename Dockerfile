FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

RUN rm -f .env \
    && rm -rf bootstrap/cache/*.php \
    && rm -rf storage/framework/sessions/* \
    && rm -rf storage/framework/views/*.php \
    && rm -rf storage/framework/cache/data/*

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# SCRIPT DE BOOT COM INJEÇÃO DE SQL
RUN echo '#!/bin/sh\n\
php artisan config:clear\n\
# Comando para injetar o arquivo install.sql usando a sua variável DATABASE_URL\n\
psql $DATABASE_URL -f /var/www/html/sql/install.sql\n\
sed -i "s/'\''key'\'' => .*,/'\''key'\'' => '\''base64:OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ='\'' ,/g" config/app.php\n\
php artisan key:generate --force\n\
php artisan jwt:secret --force\n\
php artisan config:cache\n\
php artisan route:cache\n\
apache2-foreground' > /usr/local/bin/deploy-rocket.sh

RUN chmod +x /usr/local/bin/deploy-rocket.sh

ENTRYPOINT ["deploy-rocket.sh"]
