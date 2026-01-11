FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# 1. LIMPEZA TOTAL DE CACHE NO BUILD
RUN rm -f .env && find bootstrap/cache -type f -not -name '.gitignore' -delete

# 2. INSTALAÇÃO DO COMPOSER
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# 3. A INJEÇÃO LETAL (Substituindo o código que você me enviou)
# Vamos trocar 'key' => env('APP_KEY') por uma chave real e fixa
# E garantir que a 'cipher' seja exatamente AES-256-CBC
RUN sed -i "s/'key' => env('APP_KEY'),/'key' => 'base64:OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ=',/g" config/app.php && \
    sed -i "s/'cipher' => 'AES-256-CBC',/'cipher' => 'AES-256-CBC',/g" config/app.php

# 4. PERMISSÕES
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 5. EXECUÇÃO SEM DESCULPAS
# O 'config:cache' aqui vai ler a chave que injetamos acima
ENTRYPOINT ["/bin/sh", "-c", " \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan jwt:secret --force && \
    php artisan migrate --force && \
    apache2-foreground"]
