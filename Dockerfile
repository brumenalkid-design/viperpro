FROM php:8.2-apache

# Instalação de dependências do sistema
RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

# Habilita o mod_rewrite do Apache para o Laravel
RUN a2enmod rewrite

WORKDIR /var/www/html
COPY . .

# Instala o Composer e as dependências do projeto
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# Define permissões agressivas para garantir que o Erro 500 não volte
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Configura o Apache para a pasta /public do Laravel
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# O COMANDO QUE VENCE O SISTEMA:
# 1. Deleta caches físicos que causam o erro de Cipher
# 2. Injeta uma APP_KEY válida de 32 caracteres diretamente na memória
# 3. Gera o JWT_SECRET e roda as migrations
ENTRYPOINT ["/bin/sh", "-c", "rm -rf bootstrap/cache/*.php storage/framework/sessions/* storage/framework/views/*.php && export APP_KEY=base64:OTY4N2Y1ZTM0YjI5ZDVhZDVmOTU1ZTM2ZDU4NTQ= && php artisan config:clear && php artisan cache:clear && php artisan jwt:secret --force && php artisan migrate --force && apache2-foreground"]
