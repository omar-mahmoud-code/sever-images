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

# Create log files
RUN touch /var/log/nginx/nginx.log /var/log/nginx/nginx_err.log
RUN touch /var/log/php-fpm/php-fpm.log /var/log/php-fpm/php-fpm_err.log

# Expose port 80
EXPOSE 80

# Start Supervisor with the configuration file
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
