#!/bin/bash
# MongoDB Backup Script
# Usage: ./backup.sh [database_name]
# Run with cron: 0 2 * * * /path/to/backup.sh >> /var/log/mongodb-backup.log 2>&1

set -e

# Configuration
BACKUP_DIR="/backups/mongodb"
MONGO_HOST="localhost"
MONGO_PORT="27017"
MONGO_USER="backup_user"
MONGO_PASSWORD="CHANGE_THIS_BACKUP_PASSWORD"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)

# Database to backup (empty = all databases)
DATABASE="${1:-}"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "=== MongoDB Backup Started at $(date) ==="

# Backup command
if [ -z "$DATABASE" ]; then
    echo "Backing up all databases..."
    BACKUP_NAME="all_databases_${DATE}"
    mongodump \
        --host="$MONGO_HOST" \
        --port="$MONGO_PORT" \
        --username="$MONGO_USER" \
        --password="$MONGO_PASSWORD" \
        --authenticationDatabase=admin \
        --out="$BACKUP_DIR/$BACKUP_NAME" \
        --gzip
else
    echo "Backing up database: $DATABASE"
    BACKUP_NAME="${DATABASE}_${DATE}"
    mongodump \
        --host="$MONGO_HOST" \
        --port="$MONGO_PORT" \
        --username="$MONGO_USER" \
        --password="$MONGO_PASSWORD" \
        --authenticationDatabase=admin \
        --db="$DATABASE" \
        --out="$BACKUP_DIR/$BACKUP_NAME" \
        --gzip
fi

# Create compressed archive
echo "Creating compressed archive..."
cd "$BACKUP_DIR"
tar -czf "${BACKUP_NAME}.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"

# Calculate backup size
BACKUP_SIZE=$(du -h "${BACKUP_NAME}.tar.gz" | cut -f1)
echo "Backup completed: ${BACKUP_NAME}.tar.gz (${BACKUP_SIZE})"

# Remove old backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$RETENTION_DAYS -delete

# List current backups
echo "Current backups:"
ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No backups found"

echo "=== MongoDB Backup Completed at $(date) ==="

# Optional: Upload to S3/Cloud storage
# aws s3 cp "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" "s3://your-bucket/mongodb-backups/"

exit 0
