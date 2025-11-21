#!/bin/bash
# Create OpenWrt VM (ISO can be attached later manually)
# Default VMID: 910 (Test/Dev range per VMID schema)

set -euo pipefail

VMID=${VMID:-910}
VM_NAME=${VM_NAME:-"openwrt"}
MEMORY=${MEMORY:-2048}
CORES=${CORES:-2}
DISK_SIZE=${DISK_SIZE:-8}
STORAGE=${STORAGE:-"vm-disks"}

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                        Creating OpenWrt VM                       ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

if qm status "$VMID" &>/dev/null; then
  echo "⚠️  VM $VMID already exists!"
  read -p "Delete and recreate? (y/N): " confirm
  if [[ $confirm == [yY] ]]; then
    echo "Stopping and removing VM $VMID..."
    qm stop "$VMID" 2>/dev/null || true
    qm destroy "$VMID"
  else
    echo "Aborted."
    exit 1
  fi
fi

echo "📦 Creating VM $VMID ($VM_NAME)..."
qm create "$VMID" \
  --name "$VM_NAME" \
  --memory "$MEMORY" \
  --cores "$CORES" \
  --cpu host \
  --ostype l26 \
  --machine q35 \
  --bios seabios \
  --scsihw virtio-scsi-pci \
  --vga std \
  --serial0 socket \
  --agent enabled=1

echo "✅ VM created (SeaBIOS, std VGA, serial socket)"

echo "💾 Adding boot disk (${DISK_SIZE}GB)..."
qm set "$VMID" --scsi0 "${STORAGE}:${DISK_SIZE},cache=writeback,discard=on,ssd=1"

echo "🌐 Configuring network interfaces..."
qm set "$VMID" \
  --net0 virtio,bridge=vmbr0,firewall=0 \
  --net1 virtio,bridge=vmbr0,firewall=0
echo "✅ Network configured (2 interfaces on vmbr0)"

echo ""
echo "🔌 Attach ISO later via GUI:"
echo "   Proxmox → VM $VMID → Hardware → CD/DVD Drive → Use ISO Image → (OpenWrt ISO)"
echo "   Then start the VM and install."
echo ""
echo "🔧 Optional QAT VF Passthrough (example after install):"
echo "   Use scripts/assign-qat-to-openwrt.sh to move VFs 01:01.3-6 to this VM."
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                     VM Configuration Summary                     ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
qm config "$VMID"

echo ""
echo "✅ Done. You can now attach the ISO and start the VM: qm start $VMID"
