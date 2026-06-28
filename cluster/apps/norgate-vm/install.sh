#!/usr/bin/env bash
# Manual steps after ArgoCD sync — requires kubectl + virtctl + Win11 ISO.
set -euo pipefail

NS=norgate-vm
ISO_PATH="${1:-}"

if [[ -z "${ISO_PATH}" ]]; then
  echo "Usage: $0 /path/to/Win11.iso"
  exit 1
fi

echo "==> Waiting for upload DataVolume..."
kubectl get dv norgate-vm-iso -n "${NS}"
kubectl get pvc -n "${NS}" -o wide

echo "==> Port-forward CDI upload proxy (background)..."
kubectl -n cdi port-forward svc/cdi-uploadproxy 8443:443 &
PF_PID=$!
trap 'kill ${PF_PID} 2>/dev/null || true' EXIT
sleep 2

echo "==> Uploading ISO..."
virtctl image-upload dv norgate-vm-iso \
  --namespace="${NS}" \
  --size=8Gi \
  --image-path="${ISO_PATH}" \
  --uploadproxy-url=https://localhost:8443 \
  --insecure

echo "==> Upload complete. Starting VM..."
kubectl patch vm norgate-vm -n "${NS}" --type merge \
  -p '{"spec":{"runStrategy":"Always"}}'

echo "==> Open console:"
echo "    virtctl vnc norgate-vm -n ${NS}"
echo "    or https://kubevirt.rwcloud.org"
