#!/bin/sh
DATE=$(date +"%Y-%m-%d_%H-%M")
DB_DUMP="/backups/db_$DATE.sql.gz"

echo "Starting hybrid backup..."

# 1. Full DB Backup
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" | gzip > "$DB_DUMP"
echo "Database dumped locally."

# 2. Upload DB dump to S3/Cloudflare R2
aws s3 cp "$DB_DUMP" "$S3_BUCKET/database/" --endpoint-url "$S3_ENDPOINT"
echo "Database synced to cloud."

# 3. Incremental File Sync (Only uploads new/changed files)
aws s3 sync /var/www/html/wp-content "$S3_BUCKET/wp-content/" --delete --endpoint-url "$S3_ENDPOINT"
echo "Files synced to cloud."

# 4. Clean up local DB dumps older than 7 days
find /backups -type f -name "*.gz" -mtime +7 -exec rm {} \;
echo "Local cleanup complete."
