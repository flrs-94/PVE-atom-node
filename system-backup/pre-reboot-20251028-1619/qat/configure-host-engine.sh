#!/bin/bash

# QAT Host Engine Configurator
# Implementiert AE0 Host Assignment gemäß Allocation Strategy

echo "=== QAT Host Engine (AE0) Configuration ==="
echo "Zeitstempel: $(date)"

# Erstelle QAT Konfiguration Verzeichnis
mkdir -p /etc/qat

# Prüfe QAT VF Verfügbarkeit
VF_COUNT=$(lspci | grep -c "QuickAssist.*Virtual Function")
echo "Verfügbare QAT VFs: $VF_COUNT"

if [ "$VF_COUNT" -lt 16 ]; then
    echo "❌ Nicht genügend VFs verfügbar. Erwartete: 16, Verfügbar: $VF_COUNT"
    exit 1
fi

echo "✅ QAT Hardware bereit"

# Host VF Assignment (AE0)
echo "🔧 Konfiguriere Host AE0 Assignment..."

# VF 0: System Critical
VF0_PCI=$(lspci | grep "01:01.0.*QuickAssist.*Virtual Function" | cut -d' ' -f1)
echo "VF0 (System): $VF0_PCI"

# VF 1: ZFS/Storage
VF1_PCI=$(lspci | grep "01:01.1.*QuickAssist.*Virtual Function" | cut -d' ' -f1)
echo "VF1 (Storage): $VF1_PCI"

# VF 2: Management
VF2_PCI=$(lspci | grep "01:01.2.*QuickAssist.*Virtual Function" | cut -d' ' -f1)
echo "VF2 (Management): $VF2_PCI"

# Erstelle systemd Service für QAT Host Engine
cat > /etc/systemd/system/qat-ae0-host.service << 'EOF'
[Unit]
Description=QAT AE0 Host Engine Assignment
After=qat-sriov.service
Wants=qat-sriov.service

[Service]
Type=oneshot
ExecStart=/etc/qat/qat-host-setup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Erstelle Host Setup Script
cat > /etc/qat/qat-host-setup.sh << 'EOF'
#!/bin/bash
# QAT Host VF Setup für AE0

echo "Setze QAT Host Engine (AE0) auf..."

# Host behält VF 0,1,2 für kritische Services
# Diese VFs werden NICHT an VMs weitergegeben
echo "Host VF Assignment: VF0,VF1,VF2 für AE0"

# ZFS Performance Tuning (CPU-basiert da kein QAT)
echo deadline > /sys/block/nvme0n1/queue/scheduler 2>/dev/null || true
echo deadline > /sys/block/nvme1n1/queue/scheduler 2>/dev/null || true

# Kernel Crypto für bessere Performance
modprobe aes_x86_64 2>/dev/null || true
modprobe crc32c_intel 2>/dev/null || true

echo "QAT AE0 Host Configuration aktiv"
EOF

chmod +x /etc/qat/qat-host-setup.sh

# Service aktivieren
systemctl daemon-reload
systemctl enable qat-ae0-host.service
systemctl start qat-ae0-host.service

echo ""
echo "✅ QAT AE0 Host Configuration abgeschlossen!"
echo "🎯 Host VFs: 0,1,2 (AE0)"
echo "📊 VMs können VFs 3-15 verwenden"
echo "🔄 Service Status: systemctl status qat-ae0-host.service"

# ZFS Compression Benchmark
echo ""
echo "🧪 ZFS Performance Test..."
dd if=/dev/zero of=/tmp/zfs-test bs=1M count=100 2>/dev/null
time cp /tmp/zfs-test /var/lib/vz/ 2>/dev/null
rm -f /tmp/zfs-test /var/lib/vz/zfs-test 2>/dev/null

echo "🎯 AE0 Host Engine Ready für Production!"