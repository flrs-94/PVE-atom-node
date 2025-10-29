#!/bin/bash
# Create pfSense Plus VM with QAT VF Passthrough
# VMID: 100 (Infrastructure range)
# QAT: VF 3-6 (AE1 - IPsec/SSL Offload)

set -e

VMID=100
VM_NAME="pfsense-gw"
ISO="local-isos:iso/netgate-installer-v1.0-RC-amd64-20240919-1435.iso"
MEMORY=4096
CORES=4
DISK_SIZE=16
STORAGE="vm-disks"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║          Creating pfSense Plus VM with QAT Passthrough          ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Check if VM already exists
if qm status $VMID &>/dev/null; then
    echo "⚠️  VM $VMID already exists!"
    read -p "Delete and recreate? (y/N): " confirm
    if [[ $confirm == [yY] ]]; then
        echo "Stopping and removing VM $VMID..."
        qm stop $VMID 2>/dev/null || true
        qm destroy $VMID
    else
        echo "Aborted."
        exit 1
    fi
fi

echo "📦 Creating VM $VMID ($VM_NAME)..."

# Create VM
qm create $VMID \
  --name "$VM_NAME" \
  --memory $MEMORY \
  --cores $CORES \
  --cpu host \
  --ostype l26 \
  --machine q35 \
  --bios seabios \
  --scsihw virtio-scsi-pci \
  --vga std \
  --serial0 socket \
  --bootdisk scsi0 \
  --boot order=ide2 \
  --cdrom "$ISO" \
  --agent enabled=1

echo "✅ VM created (SeaBIOS for better console compatibility)"

# Add boot disk
echo "💾 Adding boot disk (${DISK_SIZE}GB)..."
qm set $VMID --scsi0 "${STORAGE}:${DISK_SIZE},cache=writeback,discard=on,ssd=1"

# Network configuration
echo "🌐 Configuring network interfaces..."
# net0 = WAN (vmbr0 for now, can be changed later to dedicated WAN interface)
# net1 = LAN (vmbr0)
qm set $VMID \
  --net0 virtio,bridge=vmbr0,firewall=0 \
  --net1 virtio,bridge=vmbr0,firewall=0

echo "✅ Network configured (2 interfaces)"
echo "   net0: WAN (change to dedicated interface later)"
echo "   net1: LAN (vmbr0)"

# QAT VF Passthrough (VF 3-6 from AE1)
echo ""
echo "🔧 Configuring QAT VF Passthrough..."
echo "   QAT VFs: 01:01.3, 01:01.4, 01:01.5, 01:01.6 (AE1)"

# Note: VFs need to be bound to vfio-pci first (done by separate script)
qm set $VMID \
  --hostpci0 0000:01:01.3,pcie=1 \
  --hostpci1 0000:01:01.4,pcie=1 \
  --hostpci2 0000:01:01.5,pcie=1 \
  --hostpci3 0000:01:01.6,pcie=1

echo "✅ QAT VFs assigned (4x VFs from AE1)"

# Display configuration
echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                     VM Configuration Summary                     ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
qm config $VMID

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                         Next Steps                               ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "1️⃣  Bind QAT VFs 3-6 to vfio-pci:"
echo "   /root/PVE-atom-node/scripts/bind-pfsense-qat-vfs.sh"
echo ""
echo "2️⃣  Start VM:"
echo "   qm start $VMID"
echo ""
echo "3️⃣  Access Console:"
echo "   Proxmox GUI → VM $VMID → Console"
echo "   Or: qm terminal $VMID"
echo ""
echo "4️⃣  After pfSense Installation:"
echo "   - Install QAT drivers (pkg install qat)"
echo "   - Configure IPsec with QAT acceleration"
echo "   - Setup OpenVPN with hardware crypto"
echo ""
echo "📚 Documentation:"
echo "   See: docs/pfSense_QAT_Setup_Guide.md (to be created)"
echo ""

