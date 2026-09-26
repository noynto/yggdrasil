#!/usr/bin/env bash
# Validates every manifest and every Kustomize build against Kubernetes and CRD schemas.
# Requires: kubeconform, and kustomize or kubectl.
set -euo pipefail

cd "$(dirname "$0")/.."

kubeconform_flags=(
  -strict
  -ignore-missing-schemas
  -skip Secret
  -schema-location default
  -schema-location "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json"
  -summary
)

if [ -n "${KUBECONFORM_CACHE:-}" ]; then
  mkdir -p "$KUBECONFORM_CACHE"
  kubeconform_flags+=(-cache "$KUBECONFORM_CACHE")
fi

if command -v kustomize >/dev/null; then
  build=(kustomize build)
else
  build=(kubectl kustomize)
fi

echo "==> Validating manifests"
find . -path ./.git -prune -o -type f -name '*.yaml' ! -name 'kustomization.yaml' ! -path './.github/*' -print0 |
  xargs -0 kubeconform "${kubeconform_flags[@]}"

echo "==> Validating Kustomize builds"
find . -path ./.git -prune -o -type f -name 'kustomization.yaml' -print0 |
  while IFS= read -r -d '' file; do
    dir=$(dirname "$file")
    echo "--- ${dir}"
    "${build[@]}" "$dir" | kubeconform "${kubeconform_flags[@]}"
  done
