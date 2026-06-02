# 🌳 Yggdrasil

> L'arbre cosmique qui relie et soutient tous les mondes.

GitOps repository for my homelab infrastructure, managed by [Flux CD](https://fluxcd.io/).

## Clusters

| Cluster | Host      | Description                              |
|---|-----------|------------------------------------------|
| `frigg` | Geekom A7 | Noeud du cluster (controlplane + worker) |

## Stack

| Component | Tool |
|---|---|
| OS | [Talos Linux](https://talos.dev) |
| Kubernetes | 1.36 |
| GitOps | [Flux CD](https://fluxcd.io) v2 |
| Ingress | [ingress-nginx](https://kubernetes.github.io/ingress-nginx) |
| Certificates | [cert-manager](https://cert-manager.io) + Let's Encrypt |
| Load Balancer | [MetalLB](https://metallb.universe.tf) |
| Storage | [Longhorn](https://longhorn.io) |
| Secrets | [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) |

## Repository Structure

\`\`\`
yggdrasil/
├── clusters/
│   └── frigg/              # Cluster-specific Flux config
├── infrastructure/
│   ├── controllers/        # Helm releases (system components)
│   └── configs/            # Kubernetes configs
└── apps/                   # Applications
\`\`\`

## Security

All secrets are encrypted using [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets).
Plain Kubernetes secrets are never committed to this repository.
