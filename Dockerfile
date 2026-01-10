FROM php:8.2-apache

# 1. Instalação de dependências do sistema e extensões PHP necessárias
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libicu-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath

# 2. Ativa o módulo de reescrita do Apache (essencial para Laravel)
RUN a2enmod rewrite

# 3. Define o diretório de trabalho
WORKDIR /var/www/html

# 4. Copia os arquivos do seu projeto para o container
COPY . /var/www/html

# 5. Instala o Composer e as dependências do projeto
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts

# 6. Dá permissão total para as pastas de cache e logs (evita erros de escrita)
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 7. Configura o Apache para apontar para a pasta /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# 8. COMANDO DE INICIALIZAÇÃO:
# Limpa configurações antigas, roda as migrações no banco e liga o servidor
CMD php artisan config:clear && php artisan migrate --force && apache2-foreground
