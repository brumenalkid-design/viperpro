FROM php:8.2-apache

# 1. Preparação do Terreno (Performance Máxima)
RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# 2. ANULAÇÃO DE CACHE (Operação Limpa)
# Removemos fisicamente os arquivos que o Laravel usa para nos desobedecer
RUN rm -f .env \
    && rm -rf bootstrap/cache/*.php \
    && rm -rf storage/framework/sessions/* \
    && rm -rf storage/framework/views/*.php \
    && rm -rf storage/framework/cache/data/*

# 3. COMPOSER (Força Bruta)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# 4. DOMÍNIO DE PERMISSÕES
# O servidor Apache precisa ser o dono absoluto desses diretórios
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 5. CONFIGURAÇÃO DE ROTA DO APACHE
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 6. O ENTRYPOINT DE COMANDO TOTAL
# Aqui, em vez de apenas subir o servidor, nós limpamos o cache NO MOMENTO que o container liga.
# Se o Laravel tentar criar um cache ruim, nós o destruímos antes dele respirar.
ENTRYPOINT ["/bin/sh", "-c", " \
    php artisan config:clear && \
    php artisan cache:clear && \
    php artisan view:clear && \
    php artisan route:clear && \
    php artisan key:generate --force && \
    php artisan jwt:secret --force && \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan migrate --force && \
    apache2-foreground"]
