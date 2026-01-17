FROM php:8.2-fpm

# ===============================
# Dependências
# ===============================
RUN apt-get update && apt-get install -y \
    nginx \
    libpq-dev libicu-dev libzip-dev \
    zip unzip git \
    libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_pgsql intl zip bcmath gd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ===============================
# PHP-FPM
# ===============================
RUN sed -i 's|listen = .*|listen = 127.0.0.1:9000|' /usr/local/etc/php-fpm.d/zz-docker.conf

# ===============================
# App
# ===============================
WORKDIR /var/www/html
COPY . .

# ===============================
# Composer
# ===============================
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
RUN composer install --no-dev --optimize-autoloader --no-interaction

RUN chown -R www-data:www-data storage bootstrap/cache

# ===============================
# SUBSTITUI nginx.conf (AQUI ESTÁ A CHAVE)
# ===============================
RUN printf 'user www-data;\n\
worker_processes auto;\n\
error_log /var/log/nginx/error.log warn;\n\
pid /var/run/nginx.pid;\n\
\n\
events {\n\
    worker_connections 1024;\n\
}\n\
\n\
http {\n\
    include /etc/nginx/mime.types;\n\
    default_type application/octet-stream;\n\
\n\
    sendfile on;\n\
    keepalive_timeout 65;\n\
\n\
    server {\n\
        listen 8080;\n\
        server_name _;\n\
        root /var/www/html/public;\n\
        index index.php;\n\
\n\
        location / {\n\
            try_files $uri $uri/ /index.php?$query_string;\n\
        }\n\
\n\
        location ~ \\.php$ {\n\
            fastcgi_pass 127.0.0.1:9000;\n\
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\n\
            include fastcgi_params;\n\
        }\n\
    }\n\
}\n' > /etc/nginx/nginx.conf

# ===============================
# Start
# ===============================
CMD php-fpm -D && nginx -g "daemon off;"

