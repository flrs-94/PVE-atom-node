#!/bin/bash
# Create pfSense BACKUP VM for HA/Failover
# VMID: 101 (Infrastructure range)

set -e

VMID=101
VM_NAME="pfsense-backup"
ISO="local-isos:iso/netgate-installer-v1.0-RC-amd64-20240919-1435.iso"
MEMORY=4096
CORES=4
DISK_SIZE=16
STORAGE="vm-disks"

echo "Creating pfSense Backup VM (VMID $VMID)..."

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
  --agent enabled=1 \
  --onboot 0

echo "Adding disk..."
qm set $VMID --scsi0 "${STORAGE}:${DISK_SIZE},cache=writeback,discard=on,ssd=1"

echo "Configuring network..."
qm set $VMID \
  --net0 virtio,bridge=vmbr0,firewall=0 \
  --net1 virtio,bridge=vmbr0,firewall=0

echo ""
echo "✅ Backup VM created!"
echo "   Note: QAT VFs NOT assigned (will be moved on failover)"
echo ""
