#!/bin/bash
set -euo pipefail

mkdir -p backups
DATE=$(date +%F)

docker exec pg-core pg_dumpall -U postgres |
	gzip >backups/all-$DATE.sql.gz

echo "Backup complete: backups/all-$DATE.sql.gz"

# Remove backups older than 30 days
find backups -name "all-*.sql.gz" -mtime +30 -delete 2>/dev/null || true
