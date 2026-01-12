FROM php:8.2-apache

RUN apt-get update && apt-get install -y libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath
RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# DELEÇÃO AGRESSIVA DE CACHE - Impede o erro de "Unsupported cipher"
RUN rm -f bootstrap/cache/config.php \
    && rm -f bootstrap/cache/services.php \
    && rm -f bootstrap/cache/packages.php

RUN mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache/data bootstrap/cache \
    && chmod -R 777 storage bootstrap/cache \
    && chown -R www-data:www-data /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# Comando que roda ao ligar o site: LIMPA TUDO DE NOVO
CMD ["sh", "-c", "rm -f bootstrap/cache/*.php && php artisan config:clear && php artisan clear-compiled && apache2-foreground"]
