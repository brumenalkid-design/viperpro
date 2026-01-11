FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# 1. LIMPEZA BRUTAL NO BUILD (Corta o mal pela raiz)
# Removemos qualquer arquivo dentro de bootstrap/cache exceto o .gitignore
# Removemos o .env para garantir que ele use as variáveis da Render
RUN find bootstrap/cache -type f -not -name '.gitignore' -delete \
    && rm -rf storage/framework/sessions/* \
    && rm -f .env

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# 2. INJEÇÃO DIRETA DE CHAVE (Não depende de arquivo .env)
# Vamos definir a chave como uma variável de ambiente do sistema
ENV APP_KEY=base64:OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ=
ENV APP_CIPHER=AES-256-CBC

RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 777 /var/www/html/storage /var/www/html/bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 3. ENTRYPOINT SEM CACHE (O fim do ciclo)
# O comando 'config:clear' garante que o Laravel esqueça qualquer configuração anterior
ENTRYPOINT ["/bin/sh", "-c", " \
    php artisan config:clear && \
    php artisan cache:clear && \
    php artisan view:clear && \
    php artisan route:clear && \
    php artisan jwt:secret --force && \
    php artisan migrate --force && \
    apache2-foreground"]
