#!/usr/bin/env bash
# Run after Windows 11 installation is complete.
# Applies post-install GitOps changes: remove ISO, switch disk to virtio.
set -euo pipefail

VM_FILE="$(dirname "$0")/templates/norgate-vm-virtualmachine.yaml"

echo "Post-install manual steps:"
echo "1. Edit ${VM_FILE}:"
echo "   - Remove winiso disk + volume"
echo "   - Change rootdisk bus from sata to virtio"
echo "   - Set runStrategy: Always (if still Halted)"
echo "2. Optionally delete templates/norgate-vm-iso-datavolume.yaml"
echo "3. Commit and push for ArgoCD sync"
echo ""
echo "Optional LAN access: copy lan-bridge-nad.yaml from cluster/apps/nextcloud/templates/"
