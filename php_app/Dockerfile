FROM php:7.4-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    nginx \
    supervisor \
    libxml2-dev \
    libcurl4-openssl-dev \
    pkg-config \
    libonig-dev

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install pdo pdo_mysql mbstring exif xml curl zip mysqli



# Create necessary directories
RUN mkdir -p /var/log/nginx /var/log/php-fpm

# Configure Nginx
#COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY nginx/default.conf /etc/nginx/sites-available/default
# Copy Supervisor configuration
COPY nginx/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create log files
RUN touch /var/log/nginx/nginx.log /var/log/nginx/nginx_err.log
RUN touch /var/log/php-fpm/php-fpm.log /var/log/php-fpm/php-fpm_err.log

RUN chmod 777 /var/log/nginx/nginx.log /var/log/nginx/nginx_err.log
RUN chmod 777 /var/log/php-fpm/php-fpm.log /var/log/php-fpm/php-fpm_err.log

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer


# Set working directory
WORKDIR /var/www

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY php/custom-php.ini /usr/local/etc/php/conf.d/custom-php.ini

# Expose port 80
EXPOSE 80

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
