FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# 1. LIMPEZA TOTAL ANTES DE QUALQUER COISA
# Deleta fisicamente QUALQUER cache que tenha vindo do Windows/GitHub
RUN rm -rf bootstrap/cache/*.php && \
    rm -rf storage/framework/sessions/* && \
    rm -rf storage/framework/views/*.php && \
    rm -f .env

# 2. INSTALAÇÃO DO COMPOSER
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# 3. A SOBREPOSIÇÃO FINAL (A chave agora é injetada via ENV do Sistema)
# Isso garante que o PHP enxergue a chave independente do arquivo config/app.php
ENV APP_KEY=base64:OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ=
ENV APP_CIPHER=AES-256-CBC

# 4. PERMISSÕES E CONFIGURAÇÃO APACHE
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache && \
    chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 5. ENTRYPOINT "RESET DE FÁBRICA"
# Forçamos o 'config:clear' no início do boot para garantir que o cache do GitHub morra
ENTRYPOINT ["/bin/sh", "-c", " \
    php artisan config:clear && \
    php artisan cache:clear && \
    php artisan key:generate --force && \
    php artisan jwt:secret --force && \
    php artisan migrate --force && \
    apache2-foreground"]
