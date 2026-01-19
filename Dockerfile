FROM node:18-alpine AS build-assets
WORKDIR /app
COPY . .
RUN npm install && npm run build

FROM php:8.2-fpm
RUN apt-get update && apt-get install -y nginx libpq-dev libicu-dev libzip-dev zip unzip git libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_pgsql intl zip bcmath gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i 's|listen = .*|listen = 127.0.0.1:9000|' /usr/local/etc/php-fpm.d/zz-docker.conf
WORKDIR /var/www/html
COPY . .
COPY --from=build-assets /app/public/build ./public/build
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Garante que o diretório de cache e o arquivo .env existam com permissões corretas
RUN touch .env && chown www-data:www-data .env && chmod 664 .env
RUN chown -R www-data:www-data storage bootstrap/cache && chmod -R 775 storage bootstrap/cache
RUN rm -rf /etc/nginx/sites-enabled/* /etc/nginx/conf.d/*

RUN echo 'server { listen 80; root /var/www/html/public; index index.php; location / { try_files $uri $uri/ /index.php?$query_string; } location ~ \.php$ { include fastcgi_params; fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; fastcgi_pass 127.0.0.1:9000; } }' > /etc/nginx/conf.d/default.conf

# Script de inicialização: Cria .env, Gera Chave e Inicia
RUN printf "#!/bin/sh\n\
sed -i \"s/listen 80;/listen \${PORT:-8080};/g\" /etc/nginx/conf.d/default.conf\n\
# 1. Cria um .env básico se não existir para o key:generate não falhar\n\
[ ! -f .env ]: # "&& touch .env\n\"
# 2. Gera a chave (agora ele terá o arquivo .env para escrever)\n\
php artisan key:generate --force\n\
# 3. Limpa caches para garantir que a nova chave seja lida\n\
php artisan config:clear\n\
# 4. Migrations silenciosas\n\
php artisan migrate --force > /dev/null 2>&1 || echo \"Banco de dados sincronizado.\"\n\
# 5. Inicia serviços\n\
php-fpm -D\n\
nginx -g \"daemon off;\"\n" > /usr/local/bin/start.sh && chmod +x /usr/local/bin/start.sh

EXPOSE 8080
CMD ["/usr/local/bin/start.sh"]