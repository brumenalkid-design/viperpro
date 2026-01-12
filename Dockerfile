FROM php:8.2-apache

# Dependências brutas para alta performance (Site de Jogos)
RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

RUN a2enmod rewrite
WORKDIR /var/www/html
COPY . .

# 1. FAXINA FINAL (Elimina qualquer rastro de configuração antiga)
RUN rm -f .env && \
    rm -rf bootstrap/cache/*.php && \
    rm -rf storage/framework/sessions/* && \
    rm -rf storage/framework/views/*.php

# 2. INSTALAÇÃO OTIMIZADA DO COMPOSER
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# 3. PERMISSÕES DE SISTEMA (Garante que as APIs de jogos gravem dados sem erro)
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 4. CONFIGURAÇÃO DO SERVIDOR APACHE
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 5. INICIALIZAÇÃO "ZERO KM"
# Trava as configurações, gera o segredo JWT e roda as migrações do banco
ENTRYPOINT ["/bin/sh", "-c", " \
    php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache && \
    php artisan jwt:secret --force && \
    php artisan migrate --force && \
    apache2-foreground"]
