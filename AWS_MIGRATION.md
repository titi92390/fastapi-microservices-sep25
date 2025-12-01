# 🚀 Migration de votre projet Helm vers AWS EKS

Ce guide explique les modifications à apporter à vos charts Helm existants pour qu'ils fonctionnent sur AWS EKS.

## 📋 Modifications nécessaires

### 1️⃣ Créer un nouveau fichier de values pour AWS

Créez `overlays/aws-dev/values.yaml` :

```yaml
global:
  imageRegistry: docker.io
  # ⚠️ Récupérer depuis: terraform output -raw database_url
  databaseUrl: "SERA_REMPLI_PAR_TERRAFORM"
  secretKey: "SERA_REMPLI_PAR_TERRAFORM"

auth:
  ingress:
    enabled: false  # On utilise l'Ingress centralisé
  image:
    repository: leogrv22/auth
    tag: dev
  secrets:
    # Utiliser le secret Kubernetes créé par Terraform
    SECRET_KEY: null  # Sera lu depuis database-credentials
    DATABASE_URL: null  # Sera lu depuis database-credentials

users:
  ingress:
    enabled: false
  image:
    repository: leogrv22/users
    tag: dev
  secrets:
    SECRET_KEY: null
    DATABASE_URL: null

items:
  ingress:
    enabled: false
  image:
    repository: leogrv22/items
    tag: dev
  secrets:
    SECRET_KEY: null
    DATABASE_URL: null

frontend:
  image:
    registry: docker.io
    repository: leogrv22/frontend
    tag: dev
  env:
    # ⚠️ Remplacer par l'URL de l'ALB
    NEXT_PUBLIC_API_BASE: "https://api.leotest.abrdns.com"
  ingress:
    enabled: true
    host: "app.leotest.abrdns.com"
    path: /
```

### 2️⃣ Modifier les Secrets pour utiliser le Secret Kubernetes

Dans chaque service (auth, users, items), modifiez `templates/secret.yaml` :

**Avant** (secret.yaml actuel) :
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "auth.fullname" . }}-secret
type: Opaque
stringData:
  SECRET_KEY: {{ .Values.secrets.SECRET_KEY | quote }}
  DATABASE_URL: {{ .Values.secrets.DATABASE_URL | quote }}
```

**Après** (pour AWS) :
```yaml
{{- if .Values.secrets.SECRET_KEY }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "auth.fullname" . }}-secret
type: Opaque
stringData:
  SECRET_KEY: {{ .Values.secrets.SECRET_KEY | quote }}
  DATABASE_URL: {{ .Values.secrets.DATABASE_URL | quote }}
{{- end }}
```

### 3️⃣ Modifier les Deployments pour utiliser le Secret Terraform

Dans chaque `templates/deployment.yaml`, modifiez la section `envFrom` :

**Avant** :
```yaml
envFrom:
  - secretRef:
      name: {{ include "auth.fullname" . }}-secret
```

**Après** :
```yaml
envFrom:
  {{- if .Values.secrets.SECRET_KEY }}
  - secretRef:
      name: {{ include "auth.fullname" . }}-secret
  {{- else }}
  # Utiliser le secret créé par Terraform
  - secretRef:
      name: database-credentials
  {{- end }}
```

### 4️⃣ Créer un Ingress pour Traefik sur AWS

Créez `helm/platform/templates/traefik-service.yaml` :

```yaml
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: traefik
spec:
  type: NodePort
  ports:
    - name: web
      port: 80
      targetPort: 80
      nodePort: 30080
      protocol: TCP
    - name: websecure
      port: 443
      targetPort: 443
      nodePort: 30443
      protocol: TCP
  selector:
    app.kubernetes.io/name: traefik
    app.kubernetes.io/instance: traefik
```

### 5️⃣ Adapter les Ingress pour Traefik

Modifiez vos Ingress pour utiliser les annotations Traefik :

**helm/platform/templates/gateway-ingress.yaml** :

```yaml
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gateway-auth
  namespace: dev
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.ingress.kubernetes.io/router.middlewares: dev-strip-auth-prefix@kubernetescrd
spec:
  rules:
    - host: api.leotest.abrdns.com
      http:
        paths:
          - path: /auth
            pathType: Prefix
            backend:
              service:
                name: platform-auth
                port:
                  number: 80

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gateway-users
  namespace: dev
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.ingress.kubernetes.io/router.middlewares: dev-strip-users-prefix@kubernetescrd
spec:
  rules:
    - host: api.leotest.abrdns.com
      http:
        paths:
          - path: /users
            pathType: Prefix
            backend:
              service:
                name: platform-users
                port:
                  number: 80

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gateway-items
  namespace: dev
  annotations:
    kubernetes.io/ingress.class: traefik
    traefik.ingress.kubernetes.io/router.middlewares: dev-strip-items-prefix@kubernetescrd
spec:
  rules:
    - host: api.leotest.abrdns.com
      http:
        paths:
          - path: /items
            pathType: Prefix
            backend:
              service:
                name: platform-items
                port:
                  number: 80

---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: gateway-frontend
  namespace: dev
  annotations:
    kubernetes.io/ingress.class: traefik
spec:
  rules:
    - host: app.leotest.abrdns.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: platform-frontend
                port:
                  number: 80
```

## 🔄 Procédure de déploiement complète

### Étape 1 : Déployer l'infrastructure Terraform

```bash
cd terraform/

# Copier les variables pour dev
cp terraform.tfvars.dev terraform.tfvars

# Modifier les secrets
nano terraform.tfvars

# Déployer
terraform init
terraform apply

# Noter les outputs
terraform output
```

### Étape 2 : Configurer kubectl

```bash
# Récupérer la commande depuis Terraform
terraform output configure_kubectl

# Exécuter
aws eks update-kubeconfig --region eu-west-3 --name microservices-platform-dev

# Vérifier
kubectl get nodes
```

### Étape 3 : Installer Traefik

```bash
# Créer le namespace
kubectl create namespace traefik

# Installer Traefik avec Helm
helm repo add traefik https://traefik.github.io/charts
helm repo update

helm install traefik traefik/traefik \
  --namespace traefik \
  --set service.type=NodePort \
  --set ports.web.nodePort=30080 \
  --set ports.websecure.nodePort=30443 \
  --set ports.web.exposedPort=80 \
  --set ports.websecure.exposedPort=443

# Vérifier
kubectl get svc -n traefik
kubectl get pods -n traefik
```

### Étape 4 : Récupérer les credentials de la base de données

```bash
# Voir le secret créé par Terraform
kubectl get secret database-credentials -o yaml

# Décoder la DATABASE_URL
kubectl get secret database-credentials \
  -o jsonpath='{.data.DATABASE_URL}' | base64 -d

# Export pour utilisation
export DATABASE_URL=$(kubectl get secret database-credentials \
  -o jsonpath='{.data.DATABASE_URL}' | base64 -d)

echo $DATABASE_URL
```

### Étape 5 : Mettre à jour les values

Éditez `overlays/aws-dev/values.yaml` et remplacez :

```yaml
frontend:
  env:
    NEXT_PUBLIC_API_BASE: "https://api.leotest.abrdns.com"  # ✅ URL de l'ALB
```

### Étape 6 : Déployer l'application

```bash
# Depuis la racine du projet
cd ../

# Créer le namespace
kubectl create namespace dev

# Rebuild les dépendances
cd helm/platform
helm dependency update

# Déployer
helm upgrade --install platform . \
  -f ../../overlays/aws-dev/values.yaml \
  -n dev \
  --wait

# Vérifier
kubectl get pods -n dev
kubectl get svc -n dev
kubectl get ingress -n dev
```

### Étape 7 : Vérifier les logs

```bash
# Logs Traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik -f

# Logs Auth
kubectl logs -n dev -l app.kubernetes.io/name=auth -f

# Logs Frontend
kubectl logs -n dev -l app.kubernetes.io/name=frontend -f
```

### Étape 8 : Tester l'application

```bash
# Attendre que le DNS se propage (5-10 minutes)
dig api.leotest.abrdns.com
dig app.leotest.abrdns.com

# Tester l'API
curl https://api.leotest.abrdns.com/auth/health

# Tester le login
curl -X POST https://api.leotest.abrdns.com/auth/api/v1/login/access-token \
  -d "username=admin@test.com&password=Test123!"

# Tester le frontend
curl https://app.leotest.abrdns.com
```

## 🔧 Troubleshooting

### Problème : Pods ne peuvent pas se connecter à RDS

```bash
# Vérifier le secret
kubectl get secret database-credentials -o yaml

# Vérifier les security groups
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=*rds*"

# Tester la connexion depuis un pod
kubectl run psql-test --rm -it --image=postgres:15 -- \
  psql "postgresql://admin:PASSWORD@RDS_ENDPOINT:5432/microservices_dev"
```

### Problème : ALB ne route pas vers Traefik

```bash
# Vérifier le Target Group health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw alb_target_group_arn)

# Vérifier que Traefik écoute sur 30080
kubectl get svc -n traefik
kubectl port-forward -n traefik svc/traefik 30080:80

# Tester depuis un node
kubectl get nodes -o wide
ssh ec2-user@<node-ip>
curl localhost:30080/ping
```

### Problème : Certificat SSL non validé

```bash
# Vérifier le certificat
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw acm_certificate_arn)

# Vérifier les DNS records
aws route53 list-resource-record-sets \
  --hosted-zone-id $(terraform output -raw route53_zone_id)
```

## 📊 Comparaison K3s vs EKS

| Aspect | K3s (VM) | EKS (AWS) |
|--------|----------|-----------|
| Database | Pod PostgreSQL | RDS PostgreSQL Multi-AZ |
| Load Balancer | Traefik direct | ALB → Traefik |
| SSL | Manual/Let's Encrypt | Certificate Manager |
| DNS | IP publique | Route53 |
| Haute dispo | ❌ Single VM | ✅ Multi-AZ |
| Scaling | ❌ Manual | ✅ Auto-scaling |
| Backup | ❌ Manual | ✅ Automated |
| Coût | ~$10/mo | ~$260/mo |

## ✅ Checklist de migration

- [ ] Infrastructure Terraform déployée
- [ ] kubectl configuré
- [ ] Traefik installé sur EKS
- [ ] Secret database-credentials vérifié
- [ ] Values mis à jour avec les URLs AWS
- [ ] Application déployée avec Helm
- [ ] Pods running
- [ ] Ingress créés
- [ ] DNS propagé
- [ ] Certificat SSL validé
- [ ] API testée
- [ ] Frontend testé
- [ ] Logs vérifiés

## 🎯 Next Steps

1. Configurer le monitoring (CloudWatch, Prometheus)
2. Mettre en place le CI/CD (GitHub Actions → ECR → EKS)
3. Configurer les alertes
4. Documenter les runbooks
5. Tester le disaster recovery

---

**Prêt pour la production !** 🚀
