#!/bin/bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

BACKUP_DIR="/home/ubuntu/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/postgres_backup_${TIMESTAMP}.sql"

mkdir -p $BACKUP_DIR

echo "[$(date)] Début du backup PostgreSQL..."
kubectl exec postgres-postgresql-0 -n dev -- env PGPASSWORD=postgres pg_dump -U postgres -d postgres > $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "[$(date)] Backup réussi: $BACKUP_FILE"
    echo "[$(date)] Taille: $(du -h $BACKUP_FILE | cut -f1)"
else
    echo "[$(date)] ERREUR: Backup échoué!"
    exit 1
fi

# Garder les 5 derniers backups
cd $BACKUP_DIR
ls -t postgres_backup_*.sql | tail -n +6 | xargs rm -f 2>/dev/null
echo "[$(date)] Anciens backups nettoyés"
