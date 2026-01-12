FROM php:8.2-apache

RUN apt-get update && apt-get install -y libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath
RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# 1. PERMISSÕES REAIS (Acaba com o Permission Denied)
RUN mkdir -p storage/logs storage/framework/sessions storage/framework/views storage/framework/cache/data bootstrap/cache
RUN touch storage/logs/laravel.log
RUN chmod -R 777 storage bootstrap/cache
RUN chown -R www-data:www-data storage bootstrap/cache

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 2. SCRIPT DE DEPLOY "PORRADA E BOMBA"
RUN echo '#!/bin/sh\n\
# Limpa qualquer rastro de configuração antiga\n\
php artisan config:clear\n\
php artisan cache:clear\n\
php artisan view:clear\n\
\n\
# FORÇA A CIFRA AES-256-CBC NO ARQUIVO (Resolve erro de cifra)\n\
sed -i "s/'\''cipher'\'' => .*,/'\''cipher'\'' => '\''AES-256-CBC'\'',/g" config/app.php\n\
\n\
# LIMPEZA DO BANCO: Deleta as tabelas e importa o SQL zerado\n\
export PGPASSWORD=$DB_PASSWORD\n\
psql -h $DB_HOST -U $DB_USERNAME -d $DB_DATABASE -p $DB_PORT -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"\n\
psql -h $DB_HOST -U $DB_USERNAME -d $DB_DATABASE -p $DB_PORT -f /var/www/html/sql/viperpro.sql\n\
\n\
# GERAÇÃO DE CHAVES DO ZERO (Resolve erro de Secret e Key Length)\n\
php artisan key:generate --force --no-interaction\n\
php artisan jwt:secret --force --no-interaction\n\
\n\
php artisan config:cache\n\
apache2-foreground' > /usr/local/bin/deploy-rocket.sh

RUN chmod +x /usr/local/bin/deploy-rocket.sh
RUN chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

ENTRYPOINT ["deploy-rocket.sh"]

