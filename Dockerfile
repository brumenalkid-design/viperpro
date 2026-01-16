FROM php:8.2-apache

# 1. Instala extensões para Postgres e utilitários
RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

# 2. Ativa apenas o rewrite (ESSENCIAL)
RUN a2enmod rewrite

WORKDIR /var/www/html
COPY . .

# 3. Configura o Apache para a pasta /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && echo "<Directory /var/www/html/public>\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>" >> /etc/apache2/apache2.conf

# 4. Ajusta porta dinâmica para Railway
RUN sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf \
    && sed -i 's/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g' /etc/apache2/sites-available/000-default.conf

# 5. Composer e Permissões
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts
RUN chown -R www-data:www-data /var/www/html && chmod -R 775 storage bootstrap/cache

EXPOSE ${PORT}

# 6. Comando direto sem scripts intermediários
CMD ["apache2-foreground"]
