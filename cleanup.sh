#!/bin/bash

# ============================================================================
# SCRIPT DE NETTOYAGE COMPLET DE L'INFRASTRUCTURE
# ============================================================================

set -e

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${RED}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                    NETTOYAGE DE L'INFRASTRUCTURE                   ║"
echo "║                                                                    ║"
echo "║  ⚠️  ATTENTION : Cette action est IRRÉVERSIBLE !                  ║"
echo "║                                                                    ║"
echo "║  Ce script va supprimer :                                         ║"
echo "║    - Tous les pods et services Kubernetes                         ║"
echo "║    - Le cluster EKS                                               ║"
echo "║    - La base de données RDS                                       ║"
echo "║    - L'Application Load Balancer                                  ║"
echo "║    - Le VPC et tous les composants réseau                         ║"
echo "║    - Les buckets S3 (logs)                                        ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Demander confirmation
read -p "Êtes-vous ABSOLUMENT SÛR de vouloir tout supprimer ? (tapez 'YES' en majuscules) : " confirmation

if [ "$confirmation" != "YES" ]; then
    echo -e "${GREEN}❌ Annulé. Aucune suppression effectuée.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}🗑️  Début du nettoyage...${NC}"
echo ""

# ============================================================================
# ÉTAPE 1 : Supprimer les releases Helm
# ============================================================================
echo -e "${YELLOW}📦 Étape 1/5 : Suppression des releases Helm...${NC}"

if helm list -n dev | grep -q platform; then
    echo "Suppression de la release 'platform'..."
    helm uninstall platform -n dev || true
fi

if helm list -n traefik | grep -q traefik; then
    echo "Suppression de la release 'traefik'..."
    helm uninstall traefik -n traefik || true
fi

echo -e "${GREEN}✅ Releases Helm supprimées${NC}"
echo ""

# ============================================================================
# ÉTAPE 2 : Supprimer les namespaces Kubernetes
# ============================================================================
echo -e "${YELLOW}🗂️  Étape 2/5 : Suppression des namespaces...${NC}"

if kubectl get namespace dev &> /dev/null; then
    echo "Suppression du namespace 'dev'..."
    kubectl delete namespace dev --timeout=60s || true
fi

if kubectl get namespace traefik &> /dev/null; then
    echo "Suppression du namespace 'traefik'..."
    kubectl delete namespace traefik --timeout=60s || true
fi

echo -e "${GREEN}✅ Namespaces supprimés${NC}"
echo ""

# ============================================================================
# ÉTAPE 3 : Attendre que les LoadBalancers soient supprimés
# ============================================================================
echo -e "${YELLOW}⏳ Étape 3/5 : Attente de la suppression des LoadBalancers (peut prendre 2-3 min)...${NC}"

sleep 120  # Attendre 2 minutes pour que AWS supprime les LB créés par K8s

echo -e "${GREEN}✅ LoadBalancers supprimés${NC}"
echo ""

# ============================================================================
# ÉTAPE 4 : Terraform destroy
# ============================================================================
echo -e "${YELLOW}🏗️  Étape 4/5 : Destruction de l'infrastructure Terraform...${NC}"
echo -e "${RED}⚠️  Cette étape peut prendre 15-20 minutes...${NC}"
echo ""

cd terraform/

# Détruire l'infrastructure
terraform destroy -auto-approve

echo -e "${GREEN}✅ Infrastructure Terraform détruite${NC}"
echo ""

# ============================================================================
# ÉTAPE 5 : Nettoyage local
# ============================================================================
echo -e "${YELLOW}🧹 Étape 5/5 : Nettoyage local...${NC}"

# Supprimer le contexte kubectl
CLUSTER_NAME=$(terraform output -raw eks_cluster_name 2>/dev/null || echo "")
if [ -n "$CLUSTER_NAME" ]; then
    kubectl config delete-context "arn:aws:eks:eu-west-3:*:cluster/$CLUSTER_NAME" 2>/dev/null || true
    kubectl config delete-cluster "arn:aws:eks:eu-west-3:*:cluster/$CLUSTER_NAME" 2>/dev/null || true
fi

# Nettoyer les fichiers Terraform
rm -f terraform.tfstate*
rm -f .terraform.lock.hcl
rm -rf .terraform/

echo -e "${GREEN}✅ Nettoyage local terminé${NC}"
echo ""

# ============================================================================
# RÉSUMÉ
# ============================================================================
echo ""
echo -e "${GREEN}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                    ✅ NETTOYAGE TERMINÉ !                         ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo "Toutes les ressources ont été supprimées :"
echo "  ✅ Releases Helm"
echo "  ✅ Namespaces Kubernetes"
echo "  ✅ Cluster EKS"
echo "  ✅ Base de données RDS"
echo "  ✅ Load Balancers"
echo "  ✅ VPC et réseau"
echo "  ✅ Buckets S3"
echo ""
echo "💡 Vérifiez manuellement la console AWS pour confirmer que tout est bien supprimé."
echo ""
echo "Ressources à vérifier :"
echo "  - EC2 Instances"
echo "  - RDS Databases"
echo "  - Load Balancers"
echo "  - VPC"
echo "  - S3 Buckets"
echo ""
echo -e "${YELLOW}⚠️  Important : Vérifiez votre facture AWS dans quelques jours pour vous assurer qu'il n'y a plus de coûts.${NC}"
echo ""
