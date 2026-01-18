FROM php:8.2-fpm

# ===============================
# System dependencies
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
# PHP-FPM config
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
# Laravel permissions
# ===============================
RUN chown -R www-data:www-data storage bootstrap/cache \
 && chmod -R 775 storage bootstrap/cache

# ===============================
# Nginx config (ÚNICA, LIMPA)
# ===============================
RUN rm -f /etc/nginx/conf.d/*

RUN echo 'server {
    listen 80 default_server;
    server_name _;

    root /var/www/html/public;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_pass 127.0.0.1:9000;
    }
}' > /etc/nginx/conf.d/default.conf

# ===============================
# Laravel ENV safety
# ===============================
ENV APP_ENV=production
ENV LOG_CHANNEL=stderr

# ===============================
# Start services (FINAL)
# ===============================
CMD ["sh", "-c", "php artisan config:clear || true && php-fpm -F & nginx -g 'daemon off;'"]