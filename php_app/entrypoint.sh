#!/bin/bash

# Navigate to the application directory
cd /var/www/work

# Install Composer dependencies
composer install --no-dev --optimize-autoloader

# Set permissions
chown -R www-data:www-data /var/www/
chmod -R 755 /var/www/

# Start Supervisor
exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
