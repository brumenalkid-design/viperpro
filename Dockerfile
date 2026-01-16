FROM php:8.2-fpm

# 1. Instala Nginx, dependências e o pacote gettext (para usar envsubst)
RUN apt-get update && apt-get install -y \
    nginx gettext-base \
    libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath gd

# 2. Configura o PHP-FPM
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' /usr/local/etc/php-fpm.d/zz-docker.conf || true

# 3. Template do Nginx (usando $PORT como variável)
RUN echo 'server {\n\
    listen ${PORT};\n\
    server_name _;\n\
    root /var/www/html/public;\n\
    index index.php;\n\
    charset utf-8;\n\
    location / {\n\
        try_files $uri $uri/ /index.php?$query_string;\n\
    }\n\
    location ~ \.php$ {\n\
        fastcgi_pass 127.0.0.1:9000;\n\
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;\n\
        include fastcgi_params;\n\
    }\n\
}' > /etc/nginx/conf.d/default.conf.template

WORKDIR /var/www/html
COPY . .

# 4. Composer e Permissões
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts
RUN chown -R www-data:www-data /var/www/html && chmod -R 775 storage bootstrap/cache

# 5. Script de Inicialização Sênior
RUN echo "#!/bin/sh\n\
# Injeta a porta real no Nginx de forma limpa\n\
envsubst '\${PORT}' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/sites-available/default\n\
\n\
php-fpm -D\n\
nginx -g 'daemon off;'" > /usr/local/bin/start-app.sh \
    && chmod +x /usr/local/bin/start-app.sh

EXPOSE 80
CMD ["/usr/local/bin/start-app.sh"]
