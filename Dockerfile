FROM php:8.2-apache

# 1. Instala apenas o necessário para o banco e utilitários
RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

# 2. Ativa o rewrite (NÃO coloque comandos de MPM aqui)
RUN a2enmod rewrite

WORKDIR /var/www/html

# 3. Garante que os arquivos sejam copiados antes do Composer
COPY . .

# 4. Configura a pasta public e a porta dinâmica da Railway
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && echo "<Directory /var/www/html/public>\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>" >> /etc/apache2/apache2.conf

RUN sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf \
    && sed -i 's/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g' /etc/apache2/sites-available/000-default.conf

# 5. Instala dependências e ajusta permissões
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts
RUN chown -R www-data:www-data /var/www/html && chmod -R 775 storage bootstrap/cache

EXPOSE ${PORT}

# 6. Comando padrão limpo
CMD ["apache2-foreground"]
