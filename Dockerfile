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
# Remove TODA config default do nginx
# ===============================
RUN rm -rf /etc/nginx/conf.d/* \
    && rm -rf /etc/nginx/sites-enabled/* \
    && rm -rf /etc/nginx/sites-available/*

# ===============================
# Config PHP-FPM
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

# ===============================
# Permissões
# ===============================
RUN chown -R www-data:www-data storage bootstrap/cache

# ===============================
# NGINX LARAVEL (PORTA FIXA)
# ===============================
RUN printf 'server {\n\
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
}\n' > /etc/nginx/conf.d/app.conf

# ===============================
# Start
# ===============================
CMD php-fpm -D && nginx -g "daemon off;"


