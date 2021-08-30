FROM php:7.4-apache AS apiacbrliblaraveldev
RUN apt-get update
# 1. development packages
RUN apt-get install -y \
    mariadb-client \
    git \
    zip \
    curl \
    sudo \
    unzip \
    zlib1g-dev \
    libxpm-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libonig-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    libcurl4-gnutls-dev \
    g++ \
    nano

RUN apt-get install curl -y \
    && curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y \
    nodejs

# 2. apache configs + document root
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
# 3. mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin-
RUN a2enmod rewrite headers
# 4. start with base php config, then add extensions
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install \
    gd \
    bz2 \
    intl \
    iconv \
    bcmath \
    opcache \
    calendar \
    mbstring \
    curl \
    soap \
    xml \
    mysqli \
    pdo \
    pdo_mysql \
    zip
# 5. composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Downloading gcloud package
RUN apt-get install -y python
RUN curl https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz > /tmp/google-cloud-sdk.tar.gz
RUN mkdir -p /usr/local/gcloud \
    && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz \
    && "N" "n" | /usr/local/gcloud/google-cloud-sdk/install.sh

FROM apiacbrliblaraveldev as apiacbrliblaravelprod
#copia todos os arquivos para dentro da imagem
COPY . /var/www/html
#copia php.ini para configuração
#RUN rm /usr/local/etc/php/php.ini
#RUN mv /var/www/html/php.ini /usr/local/etc/php/php.ini
#copia o .env de producao
#RUN mv /var/www/html/producao.env /var/www/html/.env
#copia o config.json de producao
#RUN mv /var/www/html/public/config.json.producao /var/www/html/public/config.json
RUN composer install --no-dev --no-interaction
RUN php artisan config:cache
#RUN php artisan route:cache
RUN php artisan view:cache
RUN chown -R www-data:www-data /var/www/html/storage