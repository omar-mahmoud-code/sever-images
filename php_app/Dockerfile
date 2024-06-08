FROM php:7.3-fpm

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
    libonig-dev

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql mbstring tokenizer xml ctype json bcmath zip gd


# Create necessary directories
RUN mkdir -p /var/log/nginx /var/log/php-fpm

# Configure Nginx
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Copy Supervisor configuration
COPY nginx/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create log files
RUN touch /var/log/nginx/nginx.log /var/log/nginx/nginx_err.log
RUN touch /var/log/php-fpm/php-fpm.log /var/log/php-fpm/php-fpm_err.log

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN composer install

# Set permissions
RUN chown -R www-data:www-data /var/www/work
RUN chmod -R 755 /var/www/work

# Expose port 80
EXPOSE 80

# Start Supervisor with the configuration file
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
