#!/bin/bash

# ===============================
# PostgreSQL Backup Script
# ===============================

# Variables
NAMESPACE="fastapi"
POD_NAME=$(kubectl get pod -n $NAMESPACE -l app=postgres -o jsonpath="{.items[0].metadata.name}")
BACKUP_DIR="/tmp/postgres-backups"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="postgres_backup_$DATE.sql"

# Create backup directory
mkdir -p $BACKUP_DIR

echo "📦 Starting PostgreSQL backup..."
echo "🧠 Using pod: $POD_NAME"

# Run pg_dump inside the postgres pod
kubectl exec -n $NAMESPACE $POD_NAME -- \
  pg_dump -U app app > $BACKUP_DIR/$BACKUP_FILE

# Check result
if [ $? -eq 0 ]; then
  echo "✅ Backup successful!"
  echo "📁 File saved at: $BACKUP_DIR/$BACKUP_FILE"
else
  echo "❌ Backup failed"
  exit 1
fi
