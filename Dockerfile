FROM php:8.2-apache

# 1. Dependências de Elite
RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# 2. OPERAÇÃO LIMPEZA TOTAL (NÍVEL ATÔMICO)
RUN rm -rf .env bootstrap/cache/*.php storage/framework/sessions/* storage/framework/views/*.php storage/logs/*.log \
    && find bootstrap/cache -type f -not -name '.gitignore' -delete \
    && find storage/framework -type f -not -name '.gitignore' -delete

# 3. COMPOSER SEM CACHE
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# 4. CRIAÇÃO DO SCRIPT DE BOOT (O SEQUESTRO)
# Este script vai rodar TODA VEZ que o container ligar, limpando tudo de novo.
RUN echo '#!/bin/sh\n\
php artisan config:clear\n\
php artisan cache:clear\n\
php artisan view:clear\n\
php artisan route:clear\n\
# Forçamos a escrita da chave diretamente no arquivo de config no boot\n\
sed -i "s/'\''key'\'' => .*,/'\''key'\'' => '\''base64:OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ='\'' ,/g" config/app.php\n\
php artisan key:generate --force\n\
php artisan jwt:secret --force\n\
php artisan config:cache\n\
php artisan route:cache\n\
php artisan migrate --force\n\
exec apache2-foreground' > /usr/local/bin/deploy-rocket.sh

RUN chmod +x /usr/local/bin/deploy-rocket.sh

# 5. PERMISSÕES ABSOLUTAS
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 6. DISPARO DO SCRIPT DE BOOT
ENTRYPOINT ["deploy-rocket.sh"]
