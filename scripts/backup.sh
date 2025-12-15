#!/bin/bash

# BStock Database Backup Script
# Creates a backup of the PostgreSQL database

set -e

echo "💾 BStock Database Backup"
echo "========================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create backups directory if it doesn't exist
mkdir -p backups

# Get current timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backups/bstock_backup_${TIMESTAMP}.sql"

echo -e "${YELLOW}📦 Creating database backup...${NC}"

# Run backup using docker-compose
docker-compose -f docker-compose.prod.yml --profile backup run --rm db-backup

# Check if backup was created
if [ -f "${BACKUP_FILE}" ]; then
    echo -e "${GREEN}✅ Backup created successfully: ${BACKUP_FILE}${NC}"
    
    # Show backup size
    BACKUP_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    echo "📊 Backup size: ${BACKUP_SIZE}"
    
    # List recent backups
    echo ""
    echo "📋 Recent backups:"
    ls -lah backups/*.sql | tail -5
else
    echo "⚠️  Backup file not found. Check Docker logs for errors."
    docker-compose -f docker-compose.prod.yml logs db-backup
fi

echo ""
echo "💡 To restore from backup:"
echo "   docker-compose -f docker-compose.prod.yml exec db psql -U bstock_user -d stock_db < ${BACKUP_FILE}"
