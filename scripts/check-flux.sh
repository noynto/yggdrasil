#!/usr/bin/env bash
# Checks the consistency of the Flux resources declared in this repository:
# - every Kustomization built from this repo points to an existing directory
#   (Flux generates a kustomization.yaml when the directory has none),
# - every dependsOn refers to a Kustomization that exists,
# - every HelmRelease refers to a HelmRepository that exists.
# Requires: yq (mikefarah, v4).
set -euo pipefail

cd "$(dirname "$0")/.."

files=$(find . -path ./.git -prune -o -type f -name '*.yaml' ! -name 'kustomization.yaml' ! -name 'gotk-components.yaml' -print)
errors=0

fail() {
  echo "ERROR: $*" >&2
  errors=$((errors + 1))
}

# shellcheck disable=SC2086
kustomizations=$(yq eval-all 'select(.kind == "Kustomization" and (.apiVersion | test("^kustomize.toolkit.fluxcd.io"))) | .metadata.name' $files | grep -v '^---$' | sort -u)
# shellcheck disable=SC2086
helmrepositories=$(yq eval-all 'select(.kind == "HelmRepository") | .metadata.name' $files | grep -v '^---$' | sort -u)

echo "==> Flux Kustomizations: $(echo "$kustomizations" | tr '\n' ' ')"
echo "==> HelmRepositories: $(echo "$helmrepositories" | tr '\n' ' ')"

for file in $files; do
  # Kustomizations built from this repository (GitRepository flux-system)
  while IFS=$'\t' read -r name path; do
    [ -z "$name" ] && continue
    dir=${path#./}
    if [ ! -d "$dir" ]; then
      fail "$file: Kustomization '$name' path '$path' does not exist"
    fi
  done < <(yq eval 'select(.kind == "Kustomization" and (.apiVersion | test("^kustomize.toolkit.fluxcd.io")) and .spec.sourceRef.name == "flux-system") | [.metadata.name, .spec.path] | @tsv' "$file" | grep -v '^---$' || true)

  # dependsOn
  while IFS=$'\t' read -r name dep; do
    [ -z "$name" ] && continue
    if ! grep -qx "$dep" <<<"$kustomizations"; then
      fail "$file: Kustomization '$name' dependsOn unknown Kustomization '$dep'"
    fi
  done < <(yq eval 'select(.kind == "Kustomization" and (.apiVersion | test("^kustomize.toolkit.fluxcd.io"))) | .metadata.name as $n | .spec.dependsOn[]? | [$n, .name] | @tsv' "$file" | grep -v '^---$' || true)

  # HelmRelease -> HelmRepository
  while IFS=$'\t' read -r name repo; do
    [ -z "$name" ] && continue
    if ! grep -qx "$repo" <<<"$helmrepositories"; then
      fail "$file: HelmRelease '$name' uses unknown HelmRepository '$repo'"
    fi
  done < <(yq eval 'select(.kind == "HelmRelease") | select(.spec.chart.spec.sourceRef.kind == "HelmRepository") | [.metadata.name, .spec.chart.spec.sourceRef.name] | @tsv' "$file" | grep -v '^---$' || true)
done

if [ "$errors" -gt 0 ]; then
  echo "$errors error(s)" >&2
  exit 1
fi
echo "OK"
