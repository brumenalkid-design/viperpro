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

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader --no-interaction

RUN rm -rf bootstrap/cache/*.php storage/framework/cache/data/*
COPY --from=build-assets /app/public/build ./public/build
RUN chown -R www-data:www-data storage bootstrap/cache && chmod -R 775 storage bootstrap/cache
RUN rm -rf /etc/nginx/sites-enabled/* /etc/nginx/conf.d/*
RUN echo 'server { listen 80; root /var/www/html/public; index index.php; location / { try_files $uri $uri/ /index.php?$query_string; } location ~ \.php$ { include fastcgi_params; fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; fastcgi_pass 127.0.0.1:9000; } }' > /etc/nginx/conf.d/default.conf

# Script de inicialização: Localiza o culpado e tenta corrigir ao vivo
RUN echo '#!/bin/sh' > /usr/local/bin/start.sh
RUN echo 'sed -i "s/listen 80;/listen ${PORT:-8080};/g" /etc/nginx/conf.d/default.conf' >> /usr/local/bin/start.sh
RUN echo 'echo "--- BUSCANDO O CULPADO ---"' >> /usr/local/bin/start.sh
RUN echo 'grep -r "OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ" . || echo "Não achou base64"' >> /usr/local/bin/start.sh
RUN echo 'grep -r "9687f5e34b29d5ad5f955e36d5854" . || echo "Não achou texto puro"' >> /usr/local/bin/start.sh
RUN echo 'echo "--- TENTANDO CORREÇÃO AO VIVO ---"' >> /usr/local/bin/start.sh
RUN echo 'find . -type f -name "*.php" -exec sed -i "s/OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ/uS68On6HInL6p9G6nS8z2mB1vC4xR7zN0jK3lM6pQ9w=/g" {} +' >> /usr/local/bin/start.sh
RUN echo 'php artisan config:clear' >> /usr/local/bin/start.sh
RUN echo 'php artisan migrate --force > /dev/null 2>&1' >> /usr/local/bin/start.sh
RUN echo 'php-fpm -D' >> /usr/local/bin/start.sh
RUN echo 'nginx -g "daemon off;"' >> /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8080
CMD ["/usr/local/bin/start.sh"]