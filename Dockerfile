FROM php:8.2-apache

# Instala dependências de sistema para intl e zip
RUN apt-get update && apt-get install -y \
    libpng-dev libonig-dev libxml2-dev zip unzip git curl libpq-dev libicu-dev libzip-dev \
    && docker-php-ext-install pdo pdo_pgsql pgsql mbstring exif pcntl bcmath gd intl zip

# Instala o Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
COPY . .

# Instala as bibliotecas do site
RUN composer install --no-dev --optimize-autoloader

# Permissões de pastas
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Configura o Apache para a pasta public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN a2enmod rewrite

EXPOSE 80
CMD ["apache2-foreground"]




