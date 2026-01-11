FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Permissões totais para o sistema fluir
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# O COMANDO DA VITÓRIA:
# 1. rm -rf: Apaga fisicamente os caches e as sessões antigas que estão com erro de cifra
# 2. key:generate: Cria uma chave nova e PERFEITA de 32 caracteres
# 3. migrate: Sincroniza o banco
ENTRYPOINT ["/bin/sh", "-c", "rm -rf bootstrap/cache/*.php storage/framework/sessions/* storage/framework/views/*.php && php artisan key:generate --force && php artisan jwt:secret --force && php artisan config:clear && php artisan cache:clear && php artisan migrate --force && apache2-foreground"]
