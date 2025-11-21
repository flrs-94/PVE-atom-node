#!/bin/bash
# Create OPNsense VM for evaluation (optional QAT VF passthrough)
# VMID: 900 (Test/Dev range per VMID schema)

set -e

VMID=${VMID:-900}
VM_NAME=${VM_NAME:-"opnsense-gw"}
# Adjust ISO filename/version to what you downloaded into local-isos
ISO=${ISO:-"local-isos:iso/OPNsense-25.1-OpenSSL-dvd-amd64.iso"}
MEMORY=${MEMORY:-4096}
CORES=${CORES:-4}
DISK_SIZE=${DISK_SIZE:-16}
STORAGE=${STORAGE:-"vm-disks"}

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                     Creating OPNsense VM                         ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

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

echo "✅ VM created (SeaBIOS for broad console compatibility)"

echo "💾 Adding boot disk (${DISK_SIZE}GB)..."
qm set $VMID --scsi0 "${STORAGE}:${DISK_SIZE},cache=writeback,discard=on,ssd=1"

echo "🌐 Configuring network interfaces..."
qm set $VMID \
  --net0 virtio,bridge=vmbr0,firewall=0 \
  --net1 virtio,bridge=vmbr0,firewall=0
echo "✅ Network configured (2 interfaces)"

echo ""
echo "🔧 QAT VF Passthrough (optional)"
echo "   If you want to test QAT with OPNsense, first unassign VFs from pfSense"
echo "   and bind them to vfio-pci on the host. Then attach here (example):"
echo "   qm set $VMID \\
  --hostpci0 0000:01:01.3,pcie=1 \\
  --hostpci1 0000:01:01.4,pcie=1 \\
  --hostpci2 0000:01:01.5,pcie=1 \\
  --hostpci3 0000:01:01.6,pcie=1"

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                     VM Configuration Summary                     ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
qm config $VMID

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                            Next Steps                            ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo "1️⃣  Start VM:"
echo "   qm start $VMID"
echo ""
echo "2️⃣  Console:"
echo "   Proxmox GUI → VM $VMID → Console (std VGA)"
echo "   Or: qm terminal $VMID"
echo ""
echo "3️⃣  After OPNsense Installation:"
echo "   - Enable AES-NI (System → Settings → Misc → Cryptographic Hardware → AES-NI)"
echo "   - Optional: kldload aesni; kldload cryptodev"
echo "   - To check for QAT drivers: ls -la /boot/kernel/qat*.ko; kldload qat; kldload qat_c3xxx"
echo "     Availability depends on the OPNsense/FreeBSD version"
echo ""
echo "📌 Tip: Start with AES-NI. If QAT modules exist in your OPNsense build,"
echo "        attach the VFs and test. Otherwise consider future versions."
