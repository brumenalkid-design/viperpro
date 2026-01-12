FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# Garante que pastas críticas existam antes do boot
RUN mkdir -p storage/logs storage/framework/sessions storage/framework/views storage/framework/cache/data bootstrap/cache \
    && touch storage/logs/laravel.log \
    && chmod -R 777 storage bootstrap/cache

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# SCRIPT DE BOOT - AJUSTADO PARA USAR O APP_DEBUG DO PAINEL
RUN echo '#!/bin/sh\n\
php artisan config:clear\n\
php artisan cache:clear\n\
# Força a Key Fixa de segurança\n\
sed -i "s/'\''key'\'' => .*,/'\''key'\'' => '\''base64:OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ='\'' ,/g" config/app.php\n\
php artisan key:generate --force\n\
php artisan jwt:secret --force\n\
php artisan migrate --force\n\
chmod -R 777 storage bootstrap/cache\n\
php artisan config:cache\n\
apache2-foreground' > /usr/local/bin/deploy-rocket.sh

RUN chmod +x /usr/local/bin/deploy-rocket.sh

ENTRYPOINT ["deploy-rocket.sh"]
