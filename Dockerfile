FROM php:8.2-apache

# Instalação de dependências
RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Permissões fundamentais
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# O COMANDO QUE VAI VENCER O ERRO:
# 1. Deleta fisicamente os arquivos de cache e SESSÕES antigas (causadoras do erro de cifra)
# 2. Gera as chaves novas no tamanho exato de 32 caracteres
# 3. Limpa qualquer configuração travada
ENTRYPOINT ["/bin/sh", "-c", "rm -rf bootstrap/cache/*.php storage/framework/sessions/* storage/framework/views/*.php && php artisan key:generate --force && php artisan jwt:secret --force && php artisan config:clear && php artisan cache:clear && php artisan migrate --force && apache2-foreground"]
