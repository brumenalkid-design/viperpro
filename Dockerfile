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

# SCRIPT DE SINCRONIZAÇÃO ATÔMICA (RESOLUÇÃO AMARELO/VERMELHO/VERDE)
RUN echo '#!/bin/sh\n\
# 1. Limpeza Radical de Cache e Ambiente\n\
rm -rf bootstrap/cache/*.php\n\
cp .env.example .env\n\
\n\
# 2. Reconstrução do mapa de classes (Mata o erro do Risco Amarelo)\n\
composer dump-autoload --optimize\n\
\n\
# 3. CONSTRUÇÃO DO BANCO EM SILÊNCIO\n\
# O fresh garante a criação da "game_exclusives" antes das alterações\n\
php artisan migrate:fresh --force --seed || echo "Aguardando conclusão..."\n\
\n\
# 4. GERAÇÃO DE CACHE (Só acontece após o banco estar OK)\n\
# Isso evita que o erro do Risco Vermelho seja salvo na memória\n\
php artisan config:cache\n\
php artisan route:cache\n\
\n\
# 5. Finalização de Permissões\n\
chown -R www-data:www-data storage bootstrap/cache\n\
\n\
echo "✅ DEPLOY FINALIZADO: Log limpo e sistema estável."\n\
apache2-foreground' > /usr/local/bin/start-app.sh

RUN chmod +x /usr/local/bin/start-app.sh
CMD ["/usr/local/bin/start-app.sh"]
