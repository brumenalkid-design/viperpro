FROM php:8.2-fpm

# 1. Instala Nginx e dependências do sistema
RUN apt-get update && apt-get install -y \
    nginx \
    libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath gd

# 2. CONFIGURAÇÃO DE CONEXÃO INTERNA
# Força o PHP-FPM a escutar na porta 9000 para o Nginx
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/g' /usr/local/etc/php-fpm.d/zz-docker.conf || true

# 3. Configuração do Nginx (Escutando na porta dinâmica da Railway)
RUN echo 'server {\n\
    listen ${PORT};\n\
    server_name _;\n\
    root /var/www/html/public;\n\
    add_header X-Frame-Options "SAMEORIGIN";\n\
    add_header X-Content-Type-Options "nosniff";\n\
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
    location ~ /\.(?!well-known).* {\n\
        deny all;\n\
    }\n\
}' > /etc/nginx/sites-available/default

WORKDIR /var/www/html

# 4. Copia os arquivos do projeto
COPY . .

# 5. Instala o Composer e as dependências
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts

# 6. Ajusta permissões
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 7. Script de Inicialização Robusto e Sênior
RUN echo '#!/bin/sh\n\
# Injeta a porta real da Railway no arquivo de configuração do Nginx\n\
sed -i "s/\${PORT}/${PORT}/g" /etc/apache2/ports.conf || true\n\
sed -i "s/\${PORT}/${PORT}/g" /etc/nginx/sites-available/default\n\
\n\
# Inicia o PHP-FPM em background\n\
php-fpm -D\n\
\n\
# Inicia o Nginx em FOREGROUND (essencial para manter o container vivo)\n\
nginx -g "daemon off;"' > /usr/local/bin/start-app.sh \
    && chmod +x /usr/local/bin/start-app.sh

# A Railway usa a variável $PORT, o EXPOSE é apenas documental
EXPOSE 80

CMD ["/usr/local/bin/start-app.sh"]

# Informamos a porta 80 como padrão, mas o script acima cuida da dinâmica
EXPOSE 80

CMD ["/usr/local/bin/start-app.sh"]

