#!/bin/bash

# TrueNAS SCALE VM Creation - VMID 200
# Mit QAT AE2 (VF 7-9) für Storage Performance

set -e

VMID=200
VM_NAME="TrueNAS-SCALE"
ISO="local-isos:iso/TrueNAS-SCALE-25.04.2.5.iso"

# VM Specs
MEMORY=16384      # 16 GB RAM (min für TrueNAS)
CORES=4           # 4 CPU Cores
DISK_SIZE=32G     # Boot Disk (klein, TrueNAS nutzt separate Pools)
BRIDGE=vmbr0      # Network Bridge

echo "=== TrueNAS SCALE VM Erstellung ==="
echo "VMID: ${VMID}"
echo "Name: ${VM_NAME}"
echo "ISO:  ${ISO}"
echo ""

# Prüfe ob VMID frei ist
if qm status ${VMID} 2>/dev/null; then
    echo "❌ VMID ${VMID} bereits verwendet!"
    qm list | grep "^${VMID}"
    exit 1
fi

echo "✅ VMID ${VMID} ist verfügbar"
echo ""

# Erstelle VM
echo "🔧 Erstelle TrueNAS SCALE VM..."
qm create ${VMID} \
    --name ${VM_NAME} \
    --memory ${MEMORY} \
    --cores ${CORES} \
    --sockets 1 \
    --cpu host \
    --ostype l26 \
    --machine q35 \
    --bios ovmf \
    --efidisk0 vm-disks:1,pre-enrolled-keys=0 \
    --scsihw virtio-scsi-single \
    --scsi0 vm-disks:32 \
    --ide2 ${ISO},media=cdrom \
    --net0 virtio,bridge=${BRIDGE},firewall=1 \
    --vga qxl \
    --tablet 0 \
    --boot order=scsi0 \
    --onboot 1

echo "✅ VM erstellt"
echo ""

# Optimierungen für TrueNAS
echo "🎯 Optimiere VM für TrueNAS..."

# NUMA aktivieren für bessere Performance
qm set ${VMID} --numa 1

# CPU Type auf host für QAT Support
qm set ${VMID} --cpu host,flags=+aes

echo "✅ Optimierungen angewendet"
echo ""

# QAT VF Passthrough (AE2: VF 7, 8, 9)
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 QAT AE2 Passthrough (Storage Performance)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

VF7=$(lspci -nn | grep "QuickAssist.*Virtual" | sed -n '8p' | awk '{print $1}')
VF8=$(lspci -nn | grep "QuickAssist.*Virtual" | sed -n '9p' | awk '{print $1}')
VF9=$(lspci -nn | grep "QuickAssist.*Virtual" | sed -n '10p' | awk '{print $1}')

echo "VF PCI Adressen (AE2 - Storage):"
echo "   VF7:  ${VF7}"
echo "   VF8:  ${VF8}"
echo "   VF9:  ${VF9}"
echo ""

if [ ! -z "$VF7" ] && [ ! -z "$VF8" ] && [ ! -z "$VF9" ]; then
    echo "Konfiguriere QAT Passthrough..."
    qm set ${VMID} -hostpci0 ${VF7},pcie=1
    qm set ${VMID} -hostpci1 ${VF8},pcie=1
    qm set ${VMID} -hostpci2 ${VF9},pcie=1
    echo "✅ QAT AE2 (3x VFs) zugewiesen"
else
    echo "⚠️  Konnte nicht alle VFs finden - manuell hinzufügen"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ TrueNAS SCALE VM Erfolgreich Erstellt!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Zeige finale Config
echo "📊 VM Konfiguration:"
qm config ${VMID} | grep -E "^(name|memory|cores|net|scsi|hostpci)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Nächste Schritte:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1️⃣  VM starten:"
echo "   qm start ${VMID}"
echo ""
echo "2️⃣  Konsole öffnen:"
echo "   qm terminal ${VMID}"
echo "   oder Web-GUI: https://$(hostname -I | awk '{print $1}'):8006"
echo ""
echo "3️⃣  TrueNAS Installation:"
echo "   • Boot von ISO"
echo "   • Install TrueNAS auf Boot Disk"
echo "   • Nach Installation: ISO entfernen"
echo ""
echo "4️⃣  Storage Disks hinzufügen:"
echo "   • Über Proxmox Web-GUI oder:"
echo "   • qm set ${VMID} -scsi1 /dev/disk/by-id/XXX"
echo "   • Passthrough für dedizierte Disks"
echo ""
echo "5️⃣  QAT in TrueNAS aktivieren:"
echo "   • Nach TrueNAS Setup"
echo "   • Intel QAT Driver installieren"
echo "   • ZFS Compression mit QAT nutzen"
echo ""
echo "📈 Erwartete Performance mit QAT AE2:"
echo "   • ZFS Compression: ~1.2 GB/s DEFLATE"
echo "   • Encryption: ~8 Gbps AES-256"
echo "   • Snapshot Creation: 3-5x schneller"
echo ""
echo "🎯 VMID ${VMID}: ${VM_NAME} bereit für Installation!"
