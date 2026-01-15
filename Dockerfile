FROM php:8.2-apache

# 1. Instalação de dependências e extensões PHP
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libicu-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    postgresql-client \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

# Habilita o mod_rewrite do Apache (essencial para o Laravel)
RUN a2enmod rewrite

WORKDIR /var/www/html
COPY . .

# 2. Configurações de Ambiente
ENV APP_DEBUG=false
ENV APP_ENV=production
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# 3. Configuração do Apache (VirtualHost e Porta)
# Ajusta o DocumentRoot e garante que o Apache aceite sobrescritas (.htaccess)
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
    && echo "<Directory /var/www/html/public>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>" >> /etc/apache2/apache2.conf

# Garante que o Apache ouça a porta fornecida pela Railway ($PORT)
RUN sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf
RUN sed -i 's/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g' /etc/apache2/sites-available/000-default.conf

# 4. Instalação do Composer e Permissões
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts

RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

# 5. Script de inicialização (Ajustado)
RUN echo '#!/bin/sh\n\
# Garante que o .env exista para o Artisan não falhar\n\
if [ ! -f .env ]; then\n\
    cp .env.example .env\n\
fi\n\
\n\
# Otimizações\n\
php artisan config:cache\n\
php artisan route:cache\n\
php artisan view:cache\n\
\n\
# Migrações (Cuidado: migrate:fresh apaga os dados. Usei apenas migrate)\n\
php artisan migrate --force\n\
\n\
echo "SISTEMA ONLINE NA RAILWAY"\n\
exec apache2-foreground' > /usr/local/bin/start-app.sh

RUN chmod +x /usr/local/bin/start-app.sh

# A Railway precisa que o container exponha a porta
EXPOSE ${PORT}

CMD ["/usr/local/bin/start-app.sh"]

