#!/bin/bash

# Database and Files Backup Script
# Run this script regularly via cron

set -e

# Configuration
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Create backup directory
mkdir -p $BACKUP_DIR

echo "🗄️ Starting backup process..."

# Get database password from environment file
if [ -f .env.prod ]; then
    MYSQL_ROOT_PASSWORD=$(grep MYSQL_ROOT_PASSWORD .env.prod | cut -d '=' -f2)
else
    echo "❌ Environment file not found!"
    exit 1
fi

# Backup database
echo "📊 Backing up database..."
docker-compose -f docker-compose.prod.yml exec -T db mysqldump -u root -p$MYSQL_ROOT_PASSWORD school > $BACKUP_DIR/database_$DATE.sql

# Backup uploads directory
echo "📁 Backing up uploads..."
tar -czf $BACKUP_DIR/uploads_$DATE.tar.gz uploads/

# Backup application logs
echo "📝 Backing up logs..."
tar -czf $BACKUP_DIR/logs_$DATE.tar.gz application/logs/

# Remove old backups
echo "🧹 Cleaning old backups..."
find $BACKUP_DIR -name "*.sql" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "✅ Backup completed successfully!"
echo "📍 Backup location: $BACKUP_DIR"
ls -la $BACKUP_DIR/ | tail -5 