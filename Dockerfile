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

# SCRIPT DE INICIALIZAÇÃO (CORREÇÃO PONTUAL)
RUN echo '#!/bin/sh\n\
# Garante que o .env exista com a chave correta antes de qualquer comando\n\
echo "APP_KEY=base64:uS68On6HInL6p9G6nS8z2mB1vC4xR7zN0jK3lM6pQ9w=" > .env\n\
\n\
# Limpa o cache de configuração que trava o erro de Cipher\n\
php artisan config:clear\n\
\n\
# Tenta as migrações (se houver erro de tabela, ele ignora e segue)\n\
php artisan migrate --force || echo "Aviso: Tabelas já existem"\n\
\n\
apache2-foreground' > /usr/local/bin/start-app.sh

RUN chmod +x /usr/local/bin/start-app.sh
CMD ["/usr/local/bin/start-app.sh"]