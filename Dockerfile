FROM php:8.2-apache

RUN apt-get update && apt-get install -y libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath
RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# INJEÇÃO DA CHAVE MESTRA
ENV APP_KEY=base64:uS68On6HInL6p9G6nS8z2mB1vC4xR7zN0jK3lM6pQ9w=
ENV APP_DEBUG=true
ENV APP_ENV=production

# Garante permissões e limpa cache no build
RUN mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache/data bootstrap/cache \
    && rm -f bootstrap/cache/*.php \
    && chmod -R 777 storage bootstrap/cache \
    && chown -R www-data:www-data /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# SCRIPT DE INICIALIZAÇÃO DEFINITIVO
RUN echo '#!/bin/sh\n\
# Força a limpeza de qualquer cache que esteja escondendo a chave nova\n\
php artisan config:clear\n\
php artisan cache:clear\n\
php artisan view:clear\n\
# RE-GERA O CACHE DE CONFIGURAÇÃO COM A CHAVE NOVA\n\
php artisan config:cache\n\
# Tenta rodar as migrações\n\
php artisan migrate --force || echo "Aviso: Ignorando erro de migracao..."\n\
apache2-foreground' > /usr/local/bin/start-app.sh

RUN chmod +x /usr/local/bin/start-app.sh

CMD ["/usr/local/bin/start-app.sh"]