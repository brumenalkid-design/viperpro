FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# 1. LIMPEZA DE ELIMINAÇÃO: Remove arquivos que causam conflito de cache
RUN rm -rf bootstrap/cache/*.php storage/framework/sessions/* .env

# 2. COMPOSER
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# 3. O GOLPE DE MESTRE: Força a Cipher e a Key diretamente no arquivo config/app.php
# Isso impede que o Laravel reclame de "Unsupported Cipher" porque o valor estará 'hardcoded' no boot
RUN sed -i "/'cipher' =>/c\'cipher' => 'AES-256-CBC'," config/app.php && \
    sed -i "/'key' =>/c\'key' => 'base64:OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ='," config/app.php

# 4. PERMISSÕES
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 5. ENTRYPOINT FINAL: Sem chance de erro
ENTRYPOINT ["/bin/sh", "-c", " \
    php artisan jwt:secret --force && \
    php artisan config:clear && \
    php artisan cache:clear && \
    php artisan migrate --force && \
    apache2-foreground"]
