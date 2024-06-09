#!/bin/bash

# Variables
LOCAL_SITES_AVAILABLE_DIR="./sites-available"
NGINX_SITES_AVAILABLE_DIR="/etc/nginx/sites-available"
NGINX_SITES_ENABLED_DIR="/etc/nginx/sites-enabled"

# Check if the local directory exists
if [ ! -d "$LOCAL_SITES_AVAILABLE_DIR" ]; then
    echo "Local directory $LOCAL_SITES_AVAILABLE_DIR does not exist."
    exit 1
fi

echo "Deleting all contents inside $NGINX_SITES_AVAILABLE_DIR and $NGINX_SITES_ENABLED_DIR..."
sudo rm -rf "$NGINX_SITES_AVAILABLE_DIR"/*
sudo rm -rf "$NGINX_SITES_ENABLED_DIR"/*

# Copy the files from the local directory to the Nginx sites-available directory
echo "Copying files from $LOCAL_SITES_AVAILABLE_DIR to $NGINX_SITES_AVAILABLE_DIR..."
sudo cp "$LOCAL_SITES_AVAILABLE_DIR"/* "$NGINX_SITES_AVAILABLE_DIR"/

# Enable the sites by creating symlinks in the sites-enabled directory
for file in "$LOCAL_SITES_AVAILABLE_DIR"/*; do
    filename=$(basename "$file")
    sudo ln -s "$NGINX_SITES_AVAILABLE_DIR/$filename" "$NGINX_SITES_ENABLED_DIR/$filename"
done

# Restart Nginx to apply changes
echo "Restarting Nginx..."
sudo systemctl restart nginx

echo "Nginx sites have been copied, enabled, and Nginx has been restarted."
