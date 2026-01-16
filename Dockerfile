FROM php:8.2-apache

# 1. Instala dependências do sistema e extensões PHP necessárias
# Adicionei libpng/jpeg/freetype pois plataformas de jogos costumam precisar da extensão GD
RUN apt-get update && apt-get install -y \
    libpq-dev libicu-dev libzip-dev zip unzip git postgresql-client libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_pgsql pgsql intl zip bcmath gd

# 2. CORREÇÃO DO ERRO: Desativa o mpm_event e ativa o mpm_prefork + rewrite
# Isso resolve o erro "More than one MPM loaded"
RUN a2dismod mpm_event && a2enmod mpm_prefork rewrite

WORKDIR /var/www/html

# 3. Copia os arquivos do projeto para o container
COPY . .

# 4. Configura o DocumentRoot para a pasta /public do Laravel
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# 5. Instala o Composer e as dependências do Laravel
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs --no-scripts

# 6. Ajusta permissões de pastas essenciais do Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# 7. Script para garantir que a porta da Railway ($PORT) seja aplicada no boot
RUN echo '#!/bin/sh\n\
sed -i "s/Listen .*/Listen ${PORT}/g" /etc/apache2/ports.conf\n\
sed -i "s/<VirtualHost \*:.*/<VirtualHost *:${PORT}>/g" /etc/apache2/sites-available/000-default.conf\n\
apache2-foreground' > /usr/local/bin/start-app.sh \
    && chmod +x /usr/local/bin/start-app.sh

# A Railway usa portas dinâmicas, o EXPOSE é apenas informativo
EXPOSE ${PORT}

# Inicia o Apache através do nosso script de configuração
CMD ["/usr/local/bin/start-app.sh"]
