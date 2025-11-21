#!/bin/bash
# Configure pfSense VM networks via qm (bridges and flags)
# Usage: WAN_BRIDGE=vmbrX LAN_BRIDGE=vmbrY ./configure-pfsense-networks.sh [VMID]

set -euo pipefail

VMID=${1:-100}
WAN_BRIDGE=${WAN_BRIDGE:-vmbr0}
LAN_BRIDGE=${LAN_BRIDGE:-vmbr0}
WAN_OPTS=${WAN_OPTS:-"virtio,bridge=$WAN_BRIDGE,firewall=0"}
LAN_OPTS=${LAN_OPTS:-"virtio,bridge=$LAN_BRIDGE,firewall=0"}

echo "Configuring pfSense VM $VMID networks..."
qm set "$VMID" --net0 $WAN_OPTS --net1 $LAN_OPTS
echo "✅ pfSense VM $VMID net0=$WAN_OPTS net1=$LAN_OPTS"
