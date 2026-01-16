FROM php:8.2-apache

# 1. Instala dependências essenciais
RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

# 2. Resolve o erro de MPM e ativa Rewrite do Apache
RUN a2dismod mpm_event && a2enmod mpm_prefork && a2enmod rewrite

# 3. Define diretório de trabalho
WORKDIR /var/www/html
COPY . .

# 4. Configura o Apache para a pasta /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && echo "<Directory /var/www/html/public>\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>" >> /etc/apache2/apache2.conf

# 5. Ajusta porta dinâmica da Railway (Evita erro de Bind)
RUN sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf \
    && sed -i 's/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g' /etc/apache2/sites-available/000-default.conf

# 6. Instala Composer e limpa cache
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts

# 7. Permissões corretas
RUN chown -R www-data:www-data /var/www/html && chmod -R 775 storage bootstrap/cache

# 8. O pulo do gato: Inicia o Apache direto sem script que reseta o .env
EXPOSE ${PORT}
CMD ["apache2-foreground"]

