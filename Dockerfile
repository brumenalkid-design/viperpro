FROM php:8.2-apache

RUN apt-get update && apt-get install -y libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath
RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# CREDENCIAIS FIXAS
ENV APP_KEY=base64:uS68On6HInL6p9G6nS8z2mB1vC4xR7zN0jK3lM6pQ9w=
ENV APP_DEBUG=true
ENV APP_ENV=production
ENV DB_CONNECTION=pgsql
ENV DB_HOST=dpg-d5ilblkhg0os738mds90-a.oregon-postgres.render.com
ENV DB_DATABASE=gamedocker
ENV DB_USERNAME=gamedocker_user
ENV DB_PASSWORD=79ICALvAosgFplyYmwc3QK4gtMhfrZlC

# LIMPEZA FÍSICA RADICAL: Apaga qualquer cache que você tenha enviado no GitHub
RUN rm -rf bootstrap/cache/*.php \
    && mkdir -p storage/framework/sessions storage/framework/views storage/framework/cache/data bootstrap/cache \
    && chmod -R 777 storage bootstrap/cache \
    && chown -R www-data:www-data /var/www/html

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# SCRIPT DE INICIALIZAÇÃO DEFINITIVO (BLOQUEIA O RETORNO DE ERROS ANTIGOS)
RUN echo '#!/bin/sh\n\
# 1. DELETA OS ARQUIVOS DE CACHE FISICAMENTE (Garante que nada antigo sobreviva)\n\
rm -f bootstrap/cache/config.php\n\
rm -f bootstrap/cache/services.php\n\
rm -f bootstrap/cache/packages.php\n\
rm -f bootstrap/cache/routes-v7.php\n\
\n\
# 2. RECRIA O .ENV DO ZERO COM AS CREDENCIAIS CERTAS\n\
echo "APP_NAME=Laravel" > .env\n\
echo "APP_ENV=production" >> .env\n\
echo "APP_KEY=base64:uS68On6HInL6p9G6nS8z2mB1vC4xR7zN0jK3lM6pQ9w=" >> .env\n\
echo "APP_DEBUG=true" >> .env\n\
echo "APP_URL=https://${RENDER_EXTERNAL_HOSTNAME}" >> .env\n\
echo "DB_CONNECTION=pgsql" >> .env\n\
echo "DB_HOST=dpg-d5ilblkhg0os738mds90-a" >> .env\n\
echo "DB_PORT=5432" >> .env\n\
echo "DB_DATABASE=gamedocker" >> .env\n\
echo "DB_USERNAME=gamedocker_user" >> .env\n\
echo "DB_PASSWORD=79ICALvAosgFplyYmwc3QK4gtMhfrZlC" >> .env\n\
\n\
# 3. LIMPA TUDO VIA ARTISAN POR SEGURANÇA\n\
php artisan config:clear\n\
php artisan cache:clear\n\
\n\
# 4. SOBE O SERVIDOR SEM TENTAR MIGRAR (Para estabilizar o site primeiro)\n\
apache2-foreground' > /usr/local/bin/start-app.sh

RUN chmod +x /usr/local/bin/start-app.sh
CMD ["/usr/local/bin/start-app.sh"]