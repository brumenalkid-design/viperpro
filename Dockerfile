FROM php:8.2-apache

# Instala dependências e extensões PHP
RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

# RESOLVE O ERRO MPM (AH00534) E REWRITE
RUN a2dismod mpm_event && a2enmod mpm_prefork && a2enmod rewrite

WORKDIR /var/www/html
COPY . .

# Configurações do Apache
ENV APP_ENV=production
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && echo "<Directory /var/www/html/public>\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>" >> /etc/apache2/apache2.conf

# Ajusta porta dinâmica da Railway
RUN sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf \
    && sed -i 's/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g' /etc/apache2/sites-available/000-default.conf

# Composer e Permissões
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts
RUN chown -R www-data:www-data /var/www/html && chmod -R 775 storage bootstrap/cache

# Script de Inicialização Forçado
RUN echo '#!/bin/sh\n\
cp .env.example .env\n\
php artisan config:clear\n\
php artisan cache:clear\n\
# O segredo para o banco "railway" não existindo é garantir as variáveis no painel\n\
php artisan migrate --force\n\
echo "SISTEMA ONLINE NA RAILWAY"\n\
exec apache2-foreground' > /usr/local/bin/start-app.sh

RUN chmod +x /usr/local/bin/start-app.sh
EXPOSE ${PORT}
CMD ["/usr/local/bin/start-app.sh"]
