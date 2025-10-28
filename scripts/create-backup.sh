#!/bin/bash

# System Backup Script für PVE-atom-node
# Erstellt vollständige Sicherung aller kritischen Konfigurationen

echo "=== PVE-atom-node System Backup ==="
echo "Zeitstempel: $(date)"
echo ""

# Erstelle Backup-Verzeichnisse
mkdir -p /root/system-backup/{etc-modprobe.d,etc-systemd,usr-local-bin,ssh-config,scripts}

echo "1. Sichere modprobe Konfigurationen..."
cp /etc/modprobe.d/vfio-pci.conf /root/system-backup/etc-modprobe.d/
cp /etc/modprobe.d/vfio-sfp.conf /root/system-backup/etc-modprobe.d/ 2>/dev/null || true
cp /etc/modprobe.d/zfs-qat.conf /root/system-backup/etc-modprobe.d/
cp /etc/modprobe.d/blacklist-ixgbe.conf /root/system-backup/etc-modprobe.d/ 2>/dev/null || true

echo "2. Sichere systemd Services..."
cp /etc/systemd/system/qat-sriov.service /root/system-backup/etc-systemd/

echo "3. Sichere QAT Startup Script..."
cp /etc/qat-sriov.sh /root/system-backup/scripts/

echo "4. Sichere Custom Scripts..."
cp /usr/local/bin/qat-* /root/system-backup/usr-local-bin/
cp /usr/local/bin/sfp-* /root/system-backup/usr-local-bin/
cp /usr/local/bin/gateway-* /root/system-backup/usr-local-bin/
cp /usr/local/bin/vm-* /root/system-backup/usr-local-bin/
cp /usr/local/bin/pre-* /root/system-backup/usr-local-bin/
cp /usr/local/bin/selective-* /root/system-backup/usr-local-bin/
cp /usr/local/bin/zfs-* /root/system-backup/usr-local-bin/

echo "5. Sichere SSH Konfiguration..."
cp /root/.ssh/config /root/system-backup/ssh-config/ 2>/dev/null || true

echo "6. Erstelle Hardware-Info..."
lspci > /root/system-backup/hardware-info.txt
lscpu >> /root/system-backup/hardware-info.txt
echo "" >> /root/system-backup/hardware-info.txt
echo "=== IOMMU Groups ===" >> /root/system-backup/hardware-info.txt
find /sys/kernel/iommu_groups/ -type l | sort -V >> /root/system-backup/hardware-info.txt

echo "7. Erstelle Netzwerk-Info..."
ip link show > /root/system-backup/network-interfaces.txt
lspci | grep Ethernet >> /root/system-backup/network-interfaces.txt

echo ""
echo "✅ Backup abgeschlossen!"
echo "Dateien in: /root/system-backup/"
ls -la /root/system-backup/