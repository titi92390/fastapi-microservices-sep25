# CloudWatch Monitoring (Préparé pour AWS)

## Objectif
Ce dossier prépare l'intégration de **AWS CloudWatch** pour le monitoring
de l'infrastructure Kubernetes et des microservices FastAPI.

⚠️ Aucun service AWS payant n'est activé à ce stade.

---

## Ce qui sera monitoré sur AWS
- CPU / Mémoire des pods EKS
- Logs applicatifs FastAPI
- Logs Kubernetes (stdout / stderr)
- Santé des services

---

## Architecture cible (AWS)
Kubernetes (EKS)
  └── CloudWatch Agent
        ├── Metrics (CPU / Memory / Network)
        └── Logs (FastAPI, Traefik, system)

---

## Sécurité
- IAM Role dédié CloudWatch
- Permissions minimales
- Aucune clé AWS stockée en clair
- Compatible Vault

---

## Pourquoi CloudWatch ?
- Natif AWS
- Intégration EKS directe
- Alertes (Alarms)
- Logs centralisés
- Conforme aux exigences RNCP

---

## État actuel
✔ Monitoring local via Prometheus / Grafana  
✔ Préparation CloudWatch (documentée)  
⏳ Activation AWS prévue lors du déploiement final

---

## Activation future
L'activation réelle sera faite via :
- Terraform
- IAM Role
- Déploiement EKS
