#!/bin/bash
# MongoDB Restore Script
# Usage: ./restore.sh <backup_file.tar.gz> [database_name]

set -e

# Configuration
MONGO_HOST="localhost"
MONGO_PORT="27017"
MONGO_USER="backup_user"
MONGO_PASSWORD="CHANGE_THIS_BACKUP_PASSWORD"

# Check arguments
if [ $# -lt 1 ]; then
    echo "Usage: $0 <backup_file.tar.gz> [database_name]"
    echo "Example: $0 /backups/mongodb/all_databases_20260112_020000.tar.gz"
    echo "Example: $0 /backups/mongodb/mydb_20260112_020000.tar.gz mydb"
    exit 1
fi

BACKUP_FILE="$1"
DATABASE="${2:-}"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "=== MongoDB Restore Started at $(date) ==="
echo "Backup file: $BACKUP_FILE"

# Extract backup
TEMP_DIR=$(mktemp -d)
echo "Extracting backup to: $TEMP_DIR"
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Find the backup directory
BACKUP_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d ! -path "$TEMP_DIR" | head -n 1)

if [ -z "$BACKUP_DIR" ]; then
    echo "Error: Could not find backup directory in archive"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Restore command
if [ -z "$DATABASE" ]; then
    echo "Restoring all databases..."
    mongorestore \
        --host="$MONGO_HOST" \
        --port="$MONGO_PORT" \
        --username="$MONGO_USER" \
        --password="$MONGO_PASSWORD" \
        --authenticationDatabase=admin \
        --gzip \
        --drop \
        "$BACKUP_DIR"
else
    echo "Restoring database: $DATABASE"
    mongorestore \
        --host="$MONGO_HOST" \
        --port="$MONGO_PORT" \
        --username="$MONGO_USER" \
        --password="$MONGO_PASSWORD" \
        --authenticationDatabase=admin \
        --db="$DATABASE" \
        --gzip \
        --drop \
        "$BACKUP_DIR/$DATABASE"
fi

# Cleanup
echo "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo "=== MongoDB Restore Completed at $(date) ==="

exit 0
