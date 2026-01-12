FROM php:8.2-apache

RUN apt-get update && apt-get install -y libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath
RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# 1. FORÇA BRUTA DE PERMISSÕES (Resolve de vez o erro Permission Denied)
RUN mkdir -p storage/logs storage/framework/sessions storage/framework/views storage/framework/cache/data bootstrap/cache
RUN touch storage/logs/laravel.log
RUN chmod -R 777 storage bootstrap/cache
RUN chown -R www-data:www-data storage bootstrap/cache

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 2. SCRIPT DE DEPLOY COM CORREÇÃO DE JWT E BANCO
RUN echo '#!/bin/sh\n\
php artisan config:clear\n\
php artisan cache:clear\n\
export PGPASSWORD=$DB_PASSWORD\n\
# Injeção do banco via psql usando o arquivo confirmado no print 1000343527.png\n\
psql -h $DB_HOST -U $DB_USERNAME -d $DB_DATABASE -p $DB_PORT -f /var/www/html/sql/viperpro.sql\n\
# Resolve o erro de "Segredo não definido" do print 1000343556.png\n\
php artisan key:generate --force\n\
php artisan jwt:secret --force\n\
php artisan config:cache\n\
apache2-foreground' > /usr/local/bin/deploy-rocket.sh

# 3. FINALIZAÇÃO DE ACESSOS
RUN chmod +x /usr/local/bin/deploy-rocket.sh
RUN chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

ENTRYPOINT ["deploy-rocket.sh"]

