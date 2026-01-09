FROM php:8.2-apache

# 1. Instalar dependências do sistema e bibliotecas para as extensões exigidas
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libpng-dev \
    libicu-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    && docker-php-ext-configure intl \
    && docker-php-ext-install pdo_pgsql pgsql gd intl zip bcmath

# 2. Habilitar mod_rewrite do Apache
RUN a2enmod rewrite

# 3. Diretório de trabalho
WORKDIR /var/www/html

# 4. Copiar arquivos
COPY . .

# 5. Instalar Composer e forçar instalação ignorando travas de plataforma se necessário
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev

# 6. Permissões
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 7. DocumentRoot
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 8. Executar migrações e ligar o servidor
CMD php artisan migrate --force && apache2-foreground








