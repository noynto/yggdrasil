# 🌳 Yggdrasil

> L'arbre cosmique qui relie et soutient tous les mondes.

GitOps repository for a production-grade Kubernetes cluster, managed by [Flux CD](https://fluxcd.io/).

## Clusters

| Cluster | Host      | Description                              |
|---|-----------|------------------------------------------|
| `frigg` | Geekom A7 | Noeud du cluster (controlplane + worker) |

## Stack

| Component | Tool |
|---|---|
| OS | [Talos Linux](https://talos.dev) v1.13.0 |
| Kubernetes | 1.36 |
| GitOps | [Flux CD](https://fluxcd.io) v2 |
| Ingress | [ingress-nginx](https://kubernetes.github.io/ingress-nginx) |
| Certificates | [cert-manager](https://cert-manager.io) + Let's Encrypt |
| Load Balancer | [MetalLB](https://metallb.universe.tf) |
| Storage | [Longhorn](https://longhorn.io) |
| Secrets | Kubernetes Secrets (managed manually) |
| Notifications | Flux notification-controller → kChat (`infrastructure/configs/flux-notifications`) |

## Repository Structure

Follows the layout of Flux's [flux2-kustomize-helm-example](https://github.com/fluxcd/flux2-kustomize-helm-example), single cluster (no base/overlay split).

```
yggdrasil/
├── clusters/
│   └── frigg/              # Flux entry point (flux-system, apps.yaml, infrastructure.yaml)
├── infrastructure/
│   ├── controllers/        # System components (one directory per component)
│   └── configs/            # Custom resources that depend on the controllers
└── apps/                   # Applications (one directory per app)
```

Reconciliation order (`dependsOn`): `infrastructure-controllers` → `infrastructure-configs` → `apps`.

### Component conventions

- **Helm components** (ingress-nginx, metallb, longhorn): `helmrepository.yaml` + `helmrelease.yaml` + `namespace.yaml` in the component directory.
- **Vendored upstream manifests** (cert-manager, metrics-server): the project's official static install manifest is committed as `upstream-*.yaml` and referenced by the component's `kustomization.yaml` (plus patches if needed). No remote bases: Flux advises against fetching them at reconcile time. To upgrade, download the new release manifest, replace the file, and check for kube-system-scoped RBAC before adding any namespace override.

### Namespaces

Every `Namespace` declared here carries `kustomize.toolkit.fluxcd.io/prune: disabled`: deleting a Namespace cascades to everything inside it (PVCs, manually created Secrets), so Flux must never prune one, for instance when its manifest moves between Kustomizations. To decommission a component, delete its resources through Git, then remove the annotation from the live Namespace (or delete it by hand) once you are sure nothing in it is needed.

### App conventions

- **Apps with their own repository** (eosa, finance): `gitrepository.yaml` + `flux-kustomization.yaml` (nested Flux Kustomization). The namespace must be declared in only one place.
- **Apps with manifests in this repository** (home-automation, vaultwarden): plain manifests in the app directory.

## Apps

| App | Version | URL |
|---|---|---|
| [eosa](https://github.com/noynto/eosa) | 1.21.0 | https://eosa.me |
| [finance](https://github.com/noynto/finance) | tracks `main` | https://finance.noynto.me |
| Home Assistant (+ Mosquitto, Zigbee2MQTT) | 2026.8.2 | https://homeassistant.noynto.me |
| Vaultwarden | 1.37.2 | https://vault.noynto.me |

## Security

Secrets are managed manually with `kubectl` and never committed to this repository.
