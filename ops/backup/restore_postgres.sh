#!/bin/bash

# ===============================
# PostgreSQL Restore Script
# ===============================

NAMESPACE="fastapi"
POD_NAME=$(kubectl get pod -n $NAMESPACE -l app=postgres -o jsonpath="{.items[0].metadata.name}")
BACKUP_DIR="/tmp/postgres-backups"

if [ -z "$1" ]; then
  echo "❌ Usage: ./restore_postgres.sh <backup_file.sql>"
  exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
  echo "❌ Backup file not found: $BACKUP_DIR/$BACKUP_FILE"
  exit 1
fi

echo "♻️ Starting PostgreSQL restore..."
echo "🧠 Using pod: $POD_NAME"
echo "📂 Restoring from: $BACKUP_FILE"

# Copy backup into the pod
kubectl cp $BACKUP_DIR/$BACKUP_FILE \
  $NAMESPACE/$POD_NAME:/tmp/restore.sql

# Restore database
kubectl exec -n $NAMESPACE $POD_NAME -- \
  psql -U app app < /tmp/restore.sql

if [ $? -eq 0 ]; then
  echo "✅ Restore completed successfully!"
else
  echo "❌ Restore failed"
  exit 1
fi

