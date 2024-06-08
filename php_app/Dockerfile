FROM php:7.3-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    zip \
    unzip \
    nginx \
    supervisor

# Create necessary directories
RUN mkdir -p /var/log/nginx /var/log/php-fpm

# Configure Nginx
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Copy Supervisor configuration
COPY nginx/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose port 80
EXPOSE 80

CMD ["/usr/bin/supervisord"]
