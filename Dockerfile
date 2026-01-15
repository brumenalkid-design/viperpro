FROM php:8.2-apache

# 1. Instalação de dependências
RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

# Habilita mod_rewrite
RUN a2enmod rewrite

WORKDIR /var/www/html
COPY . .

# 2. Configurações de Ambiente
ENV APP_ENV=production
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# 3. Configuração do Apache (Corrigida para evitar erro de MPM)
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && echo "<Directory /var/www/html/public>\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>" >> /etc/apache2/apache2.conf

# Ajuste de Porta dinâmica
RUN sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf \
    && sed -i 's/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g' /etc/apache2/sites-available/000-default.conf

# 4. Composer e Permissões
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts
RUN chown -R www-data:www-data /var/www/html && chmod -R 775 storage bootstrap/cache

# 5. Script de Inicialização (Limpeza de Cache agressiva)
RUN echo '#!/bin/sh\n\
cp .env.example .env\n\
# Limpa caches para aceitar as novas variáveis do painel\n\
php artisan config:clear\n\
php artisan cache:clear\n\
\n\
# Tenta migrar (Isso vai criar as tabelas que estão vazias no seu print)\n\
php artisan migrate --force\n\
\n\
echo "SISTEMA ONLINE NA RAILWAY"\n\
exec apache2-foreground' > /usr/local/bin/start-app.sh

RUN chmod +x /usr/local/bin/start-app.sh
EXPOSE ${PORT}
CMD ["/usr/local/bin/start-app.sh"]

