#!/bin/bash
# SFP+ Passthrough Setup für pfSense und TrueNAS

echo "=== SFP+ VFIO Passthrough Setup ==="

# PCI-IDs für Intel X553 10GbE SFP+
SFP_PCI_ID="8086:15c4"
SFP_PORT1="0000:0c:00.0"  # eno3 - für pfSense
SFP_PORT2="0000:0c:00.1"  # eno4 - für TrueNAS

echo "1. Konfiguriere VFIO für SFP+ Ports..."

# VFIO-PCI Konfiguration
echo "vfio-pci" > /etc/modules-load.d/vfio.conf

# VFIO PCI-IDs setzen
echo "options vfio-pci ids=$SFP_PCI_ID" > /etc/modprobe.d/vfio-pci.conf

# Ixgbe-Treiber für diese Geräte deaktivieren
echo "softdep ixgbe pre: vfio-pci" >> /etc/modprobe.d/vfio-sfp.conf

echo "2. Aktualisiere Initramfs..."
update-initramfs -u

echo "3. SFP+ Port-Zuordnung:"
echo "   Port 1 (0c:00.0 / eno3): pfSense WAN"
echo "   Port 2 (0c:00.1 / eno4): pfSense LAN"
echo "   Port 3 (0b:00.0 / eno1): Host/TrueNAS Bridge"
echo "   Port 4 (0b:00.1 / eno2): Host/Management"

echo -e "\n4. IOMMU-Gruppen:"
echo "   Gruppe 32: $SFP_PORT1 (pfSense WAN)"
echo "   Gruppe 33: $SFP_PORT2 (pfSense LAN)"

echo -e "\n5. Nach Neustart verfügbar für VM-Passthrough!"
echo "   Neustart erforderlich: systemctl reboot"