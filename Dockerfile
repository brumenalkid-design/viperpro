FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Permissões totais - Sem frescura de acesso negado
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# O ENTRYPOINT DA IGNORÂNCIA:
# 1. Apaga fisicamente TODAS as pastas de cache e sessões (rm -rf)
# 2. Deleta o arquivo .env se ele existir (para não ler chave velha)
# 3. Gera chaves novas e FORÇA o cache da nova config
ENTRYPOINT ["/bin/sh", "-c", " \
    rm -f .env && \
    rm -rf bootstrap/cache/*.php && \
    rm -rf storage/framework/sessions/* && \
    rm -rf storage/framework/views/*.php && \
    rm -rf storage/framework/cache/data/* && \
    php artisan key:generate --force && \
    php artisan jwt:secret --force && \
    php artisan config:cache && \
    php artisan view:cache && \
    php artisan route:cache && \
    php artisan migrate --force && \
    apache2-foreground"]
