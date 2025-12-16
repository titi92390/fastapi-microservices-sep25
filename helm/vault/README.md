# Vault (optional component)

This directory provides an optional Vault setup that can be used alongside
the existing monitoring stack.

## Purpose

- Validate secret management on local or staging Kubernetes clusters
- Keep the monitoring stack unchanged
- Provide a clean base for future production integration

## Scope

- Local / staging Kubernetes only
- NOT deployed automatically
- NOT used on the final AWS EKS cluster by default

## Usage example (optional)

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault -f values.yaml

