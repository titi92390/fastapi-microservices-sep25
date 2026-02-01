#!/bin/bash
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

BACKUP_DIR="/home/ubuntu/backups"

# Lister les backups disponibles
echo "Backups disponibles :"
ls -lt $BACKUP_DIR/postgres_backup_*.sql | awk '{print NR". "$9, $6, $7, $8}'

# Utiliser le dernier backup par défaut ou celui passé en argument
BACKUP_FILE=${1:-$(ls -t $BACKUP_DIR/postgres_backup_*.sql | head -1)}

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERREUR: Fichier de backup non trouvé: $BACKUP_FILE"
    exit 1
fi

echo "[$(date)] Restauration depuis: $BACKUP_FILE"

# Supprimer les tables existantes puis restaurer
kubectl exec postgres-postgresql-0 -n dev -- env PGPASSWORD=postgres psql -U postgres -d postgres -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
kubectl exec -i postgres-postgresql-0 -n dev -- env PGPASSWORD=postgres psql -U postgres -d postgres < $BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "[$(date)] Restauration réussie!"
else
    echo "[$(date)] ERREUR: Restauration échouée!"
    exit 1
fi
