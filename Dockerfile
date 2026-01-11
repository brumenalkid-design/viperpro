FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Permissões agressivas para garantir que o Erro 500 não volte
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# O RESET TOTAL: Deleta caches físicos, gera chaves e sobe o site
ENTRYPOINT ["/bin/sh", "-c", "rm -rf bootstrap/cache/*.php storage/framework/views/*.php storage/framework/sessions/* && php artisan key:generate --force && php artisan jwt:secret --force && php artisan config:clear && php artisan cache:clear && php artisan migrate --force && apache2-foreground"]
