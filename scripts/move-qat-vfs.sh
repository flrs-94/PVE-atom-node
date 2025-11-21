#!/bin/bash
# Move the 4 QAT VFs (01:01.3-01:01.6) between two VMs safely
# Usage: ./move-qat-vfs.sh <FROM_VMID> <TO_VMID>

set -euo pipefail

FROM_VMID=${1:-}
TO_VMID=${2:-}

if [[ -z "$FROM_VMID" || -z "$TO_VMID" ]]; then
  echo "Usage: $0 <FROM_VMID> <TO_VMID>" >&2
  exit 2
fi

echo "Moving QAT VFs 0000:01:01.{3,4,5,6} from VM $FROM_VMID to VM $TO_VMID"

# Verify VMs exist
if ! qm status "$FROM_VMID" &>/dev/null; then
  echo "Source VM $FROM_VMID does not exist." >&2
  exit 1
fi
if ! qm status "$TO_VMID" &>/dev/null; then
  echo "Target VM $TO_VMID does not exist." >&2
  exit 1
fi

# Stop VMs if running (to avoid hotplug issues)
if qm status "$FROM_VMID" | grep -qi running; then
  echo "Stopping source VM $FROM_VMID..."
  qm stop "$FROM_VMID" || true
fi
if qm status "$TO_VMID" | grep -qi running; then
  echo "Stopping target VM $TO_VMID..."
  qm stop "$TO_VMID" || true
fi

echo "Detaching VFs from VM $FROM_VMID (hostpci0-3)..."
for i in 0 1 2 3; do
  if qm config "$FROM_VMID" | grep -q "^hostpci${i}:"; then
    qm set "$FROM_VMID" --delete "hostpci${i}"
  fi
done

echo "Attaching VFs to VM $TO_VMID..."
qm set "$TO_VMID" \
  --hostpci0 0000:01:01.3,pcie=1 \
  --hostpci1 0000:01:01.4,pcie=1 \
  --hostpci2 0000:01:01.5,pcie=1 \
  --hostpci3 0000:01:01.6,pcie=1

echo "✅ Moved QAT VFs from $FROM_VMID → $TO_VMID"
echo "You can now start the target VM: qm start $TO_VMID"
