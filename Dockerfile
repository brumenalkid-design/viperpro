FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Permissões de escrita - Essencial para sair do Erro 500
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# ENTRYPOINT: Onde a mágica acontece. 
# Ele gera a APP_KEY e o JWT_SECRET no tamanho correto toda vez que o container sobe.
ENTRYPOINT ["/bin/sh", "-c", "php artisan key:generate --force && php artisan jwt:secret --force && php artisan config:clear && php artisan cache:clear && php artisan migrate --force && apache2-foreground"]
