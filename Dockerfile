FROM php:8.2-apache

# 1. Instalação de dependências e extensões PHP
RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

# 2. Resolve o erro de MPM e habilita o Rewrite (Crucial para evitar o erro AH00534)
RUN a2dismod mpm_event && a2enmod mpm_prefork && a2enmod rewrite

WORKDIR /var/www/html
COPY . .

# 3. Configurações de Ambiente
ENV APP_ENV=production
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# 4. Configuração do Apache para a pasta /public e Porta Dinâmica da Railway
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && echo "<Directory /var/www/html/public>\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>" >> /etc/apache2/apache2.conf

# Ajusta o Apache para ouvir a porta injetada pela Railway ($PORT)
RUN sed -i 's/Listen 80/Listen ${PORT}/g' /etc/apache2/ports.conf \
    && sed -i 's/<VirtualHost \*:80>/<VirtualHost *:${PORT}>/g' /etc/apache2/sites-available/000-default.conf

# 5. Instalação do Composer e Permissões de Pasta
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts
RUN chown -R www-data:www-data /var/www/html && chmod -R 775 storage bootstrap/cache

# 6. Script de Inicialização (Executa as migrações no banco da Railway)
RUN echo '#!/bin/sh\n\
if [ ! -f .env ]; then\n\
    cp .env.example .env\n\
fi\n\
\n\
# Limpa caches para garantir leitura das variáveis do painel\n\
php artisan config:clear\n\
php artisan cache:clear\n\
\n\
# Executa as migrações (Cria as tabelas no seu Postgres vazio)\n\
php artisan migrate --force\n\
\n\
echo "SISTEMA ONLINE NA RAILWAY"\n\
exec apache2-foreground' > /usr/local/bin/start-app.sh

RUN chmod +x /usr/local/bin/start-app.sh

EXPOSE ${PORT}

CMD ["/usr/local/bin/start-app.sh"]

