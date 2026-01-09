FROM php:8.2-apache

# 1. Instala apenas o que o LOG pediu (intl e zip) de forma leve
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libicu-dev \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install pdo_pgsql pgsql intl zip

# 2. Ativa o redirecionamento de links
RUN a2enmod rewrite

# 3. Prepara os arquivos
WORKDIR /var/www/html
COPY . .

# 4. Instala o Composer pulando os scripts que travam o deploy
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts

# 5. Permissões de pasta (Essencial para não dar erro 500)
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 6. Aponta para a pasta /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 7. Tenta migrar; se falhar por falta de algo, ele liga o site mesmo assim
CMD php artisan migrate --force ; apache2-foreground

