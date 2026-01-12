FROM php:8.2-apache

RUN apt-get update && apt-get install -y libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath
RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# Limpeza total de cache e logs antigos
RUN rm -rf bootstrap/cache/*.php
RUN find storage/framework -type f -delete
RUN mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache/data bootstrap/cache
RUN chmod -R 777 storage bootstrap/cache
RUN chown -R www-data:www-data /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# Inicia o Apache limpando qualquer lixo de config
CMD ["sh", "-c", "php artisan config:clear && apache2-foreground"]
