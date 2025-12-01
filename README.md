# 🚀 Déploiement AWS avec Terraform

Infrastructure complète pour déployer votre plateforme de microservices sur AWS avec EKS, RDS, ALB et Route53.

## 📋 Prérequis

### Outils nécessaires
```bash
# AWS CLI
aws --version  # >= 2.0

# Terraform
terraform version  # >= 1.0

# kubectl
kubectl version --client  # >= 1.28

# Helm
helm version  # >= 3.0
```

### Configuration AWS
```bash
# Configurer AWS CLI
aws configure

# Vérifier l'accès
aws sts get-caller-identity
```

## 🏗️ Architecture

```
Internet
    │
    ├─── Route53 DNS (leotest.abrdns.com)
    │    ├─── api.leotest.abrdns.com → ALB
    │    ├─── app.leotest.abrdns.com → ALB
    │    └─── leotest.abrdns.com → ALB
    │
    ▼
Application Load Balancer (HTTPS + SSL)
    │
    ├─── Target Group (Traefik NodePort 30080)
    │
    ▼
VPC (10.0.0.0/16)
    │
    ├─── Public Subnets (2 AZ)
    │    ├─── 10.0.1.0/24  (AZ-1)
    │    ├─── 10.0.10.0/24 (AZ-2)
    │    ├─── NAT Gateway x2
    │    └─── Internet Gateway
    │
    ├─── Private Subnets EKS (2 AZ)
    │    ├─── 10.0.2.0/24  (AZ-1)
    │    ├─── 10.0.20.0/24 (AZ-2)
    │    │
    │    └─── EKS Cluster
    │         ├─── Node Group (t3.medium x2-6)
    │         ├─── Traefik (Ingress Controller)
    │         ├─── Auth Service
    │         ├─── Users Service
    │         ├─── Items Service
    │         └─── Frontend Service
    │
    └─── Private Subnets RDS (2 AZ)
         ├─── 10.0.3.0/24  (AZ-1)
         ├─── 10.0.30.0/24 (AZ-2)
         │
         └─── RDS PostgreSQL 15
              ├─── Master (AZ-1)
              └─── Standby (AZ-2) [PROD only]
```

## 📁 Structure des fichiers

```
terraform/
├── main.tf                 # Configuration principale
├── variables.tf            # Définition des variables
├── vpc.tf                  # VPC, Subnets, NAT, IGW
├── security-groups.tf      # Security Groups
├── iam.tf                  # IAM Roles et Policies
├── eks.tf                  # Cluster EKS
├── rds.tf                  # Base de données PostgreSQL
├── alb.tf                  # Application Load Balancer
├── route53.tf              # DNS et Certificat SSL
├── s3.tf                   # Buckets S3
├── outputs.tf              # Outputs
├── terraform.tfvars.dev    # Variables DEV
└── terraform.tfvars.prod   # Variables PROD
```

## 🚀 Déploiement

### 1️⃣ Préparer l'environnement

```bash
# Cloner le projet
git clone <your-repo>
cd terraform/

# Copier le fichier de variables selon l'environnement
cp terraform.tfvars.dev terraform.tfvars  # Pour DEV
# OU
cp terraform.tfvars.prod terraform.tfvars  # Pour PROD
```

### 2️⃣ Modifier les secrets (IMPORTANT ⚠️)

Éditez `terraform.tfvars` et changez :

```hcl
# ⚠️ OBLIGATOIRE : Changer ces valeurs !
rds_master_password = "VOTRE_MOT_DE_PASSE_TRES_SECURISE"
app_secret_key      = "VOTRE_SECRET_KEY_TRES_LONGUE"
```

### 3️⃣ Initialiser Terraform

```bash
terraform init
```

### 4️⃣ Planifier le déploiement

```bash
# Voir ce qui sera créé
terraform plan
```

### 5️⃣ Déployer l'infrastructure

```bash
# Déployer (durée : ~15-20 minutes)
terraform apply

# Confirmer avec : yes
```

### 6️⃣ Configurer kubectl

```bash
# Récupérer la commande depuis les outputs
terraform output configure_kubectl

# Exécuter la commande
aws eks update-kubeconfig --region eu-west-3 --name microservices-platform-dev

# Vérifier
kubectl get nodes
```

### 7️⃣ Déployer Traefik sur EKS

```bash
# Ajouter le repo Helm Traefik
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Créer le namespace
kubectl create namespace traefik

# Installer Traefik avec NodePort 30080
helm install traefik traefik/traefik \
  --namespace traefik \
  --set service.type=NodePort \
  --set ports.web.nodePort=30080 \
  --set ports.websecure.nodePort=30443

# Vérifier
kubectl get svc -n traefik
```

### 8️⃣ Déployer votre application

```bash
# Depuis la racine du projet
cd ../

# Créer le namespace
kubectl create namespace dev  # ou prod

# Mettre à jour les values avec les nouvelles URLs
# Éditer overlays/dev/values.yaml

# Déployer avec Helm
cd helm/platform
helm dependency update
helm upgrade --install platform . \
  -f ../../overlays/dev/values.yaml \
  -n dev

# Vérifier
kubectl get pods -n dev
```

### 9️⃣ Vérifier le déploiement

```bash
# Pods
kubectl get pods -n dev

# Services
kubectl get svc -n dev

# Ingress
kubectl get ingress -n dev

# Logs d'un service
kubectl logs -n dev -l app.kubernetes.io/name=auth -f
```

### 🔟 Tester l'API

```bash
# Attendre que le DNS se propage (5-10 minutes)
# Puis tester

# Health check
curl https://api.leotest.abrdns.com/health

# Login
curl -X POST https://api.leotest.abrdns.com/auth/api/v1/login/access-token \
  -d "username=admin@test.com&password=Test123!"

# Frontend
curl https://app.leotest.abrdns.com
```

## 📊 Outputs Terraform

```bash
# Voir tous les outputs
terraform output

# Voir un output spécifique
terraform output api_domain
terraform output database_url

# Export d'un output
export DATABASE_URL=$(terraform output -raw database_url)
```

## 🔐 Secrets Kubernetes

La DATABASE_URL est automatiquement créée dans Kubernetes :

```bash
# Voir le secret
kubectl get secret database-credentials -n default -o yaml

# Décoder la DATABASE_URL
kubectl get secret database-credentials -n default \
  -o jsonpath='{.data.DATABASE_URL}' | base64 -d
```

## 🗑️ Nettoyage (Détruire l'infrastructure)

```bash
# ⚠️ ATTENTION : Ceci supprime TOUT !

# Supprimer les ressources Kubernetes d'abord
helm uninstall platform -n dev
helm uninstall traefik -n traefik

# Puis détruire l'infrastructure Terraform
terraform destroy

# Confirmer avec : yes
```

## 💰 Estimation des coûts

### Environnement DEV (2-3 nodes, db.t3.small, sans Multi-AZ)
- **EKS Control Plane** : ~$73/mois
- **EC2 t3.medium x2** : ~$60/mois
- **RDS db.t3.small** : ~$30/mois
- **ALB** : ~$20/mois
- **NAT Gateway x2** : ~$65/mois
- **Total** : **~$250/mois**

### Environnement PROD (3-6 nodes, db.t3.small, Multi-AZ)
- **EKS Control Plane** : ~$73/mois
- **EC2 t3.medium x3** : ~$90/mois
- **RDS db.t3.small Multi-AZ** : ~$60/mois
- **ALB** : ~$20/mois
- **NAT Gateway x2** : ~$65/mois
- **Total** : **~$310/mois**

💡 **Pour votre cours** : Pensez à détruire l'infrastructure après vos tests !

```bash
# Script de nettoyage rapide
./cleanup.sh
```

## 🐛 Troubleshooting

### Problème : Nodes ne rejoignent pas le cluster

```bash
# Vérifier les logs des nodes
kubectl describe node

# Vérifier aws-auth configmap
kubectl get configmap aws-auth -n kube-system -o yaml
```

### Problème : Pods en CrashLoopBackOff

```bash
# Voir les logs
kubectl logs -n dev <pod-name>

# Vérifier les events
kubectl get events -n dev --sort-by='.lastTimestamp'
```

### Problème : ALB ne route pas vers Traefik

```bash
# Vérifier le Target Group
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>

# Vérifier que Traefik écoute sur NodePort 30080
kubectl get svc -n traefik
```

### Problème : Certificat SSL en attente

```bash
# Vérifier le certificat
aws acm describe-certificate \
  --certificate-arn <cert-arn>

# Vérifier les enregistrements DNS
aws route53 list-resource-record-sets \
  --hosted-zone-id <zone-id>
```

## 📚 Ressources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Helm Documentation](https://helm.sh/docs/)

## 🆘 Support

Pour toute question ou problème :
1. Vérifier les logs : `kubectl logs -n <namespace> <pod>`
2. Vérifier les events : `kubectl get events -n <namespace>`
3. Vérifier les outputs Terraform : `terraform output`
4. Contacter l'équipe support

---

**Auteur** : Votre Équipe Platform  
**Dernière mise à jour** : 2025  
**Version** : 1.0.0
