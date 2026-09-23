#!/usr/bin/env bash
# Copia i manifest di cutover (Fase 2) nei path GitOps di applications/infra.
# Non tocca il cluster: solo file nel repo. Poi commit + push → ArgoCD.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/docs/kubernetes/matrix/manifests/cutover"
APP="$ROOT/kubernetes/applications/matrix"
CF="$ROOT/kubernetes/infra/manifests/cloudflared"

cp -v "$SRC/configmap.yaml" "$APP/configmap.yaml"
cp -v "$SRC/deployment.yaml" "$APP/deployment.yaml"
cp -v "$SRC/secrets.yaml" "$APP/secrets.yaml"
cp -v "$SRC/cloudflared-configmap.yaml" "$CF/configmap.yaml"

echo
echo "Cutover files copiati nel repo."
echo "Prossimi passi:"
echo "  1. git diff / review"
echo "  2. commit + push"
echo "  3. aspetta sync ArgoCD (matrix + cloudflared/infra)"
echo "  4. verifica: curl .../versions | jq '.unstable_features[\"org.matrix.msc4108\"]'"
