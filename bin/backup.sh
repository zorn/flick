#!/usr/bin/env bash

# This script is used by Render to perform PostgreSQL backups to S3.
# See: https://render.com/docs/backup-postgresql-to-s3

# set up an exit on error
set -o errexit

# Output file
BACKUP_FILE="/tmp/backup-$(date +%Y-%m-%d-%H-%M-%S).sql"

# Dump the database
pg_dump "$DATABASE_URL" > "$BACKUP_FILE"

# Upload to S3
aws s3 cp "$BACKUP_FILE" "s3://${S3_BUCKET_NAME}/backups/$(basename "$BACKUP_FILE")"
