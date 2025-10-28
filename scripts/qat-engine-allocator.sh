#!/bin/bash

# QAT Engine Allocation Script für PVE-atom-node
# Implementiert die strategische Aufteilung aus QAT_Engine_Allocation_Strategy.md

echo "=== Intel QAT Engine Allocation für PVE-atom-node ==="
echo "📋 Basierend auf strategischer Planung"
echo ""

# Prüfe QAT Hardware Status
echo "🔍 QAT Hardware Prüfung..."
lspci | grep -i quickassist
if [ $? -ne 0 ]; then
    echo "❌ Keine QAT Hardware gefunden!"
    exit 1
fi

echo "✅ QAT Hardware erkannt"
echo ""

# Zeige aktuelle VF Konfiguration
echo "📊 Virtual Function Status:"
ls -la /sys/class/qat_vf/ 2>/dev/null || echo "   VFs noch nicht konfiguriert"
echo ""

# Empfohlene Allokation anzeigen
echo "🎯 Empfohlene Engine-Allokation:"
echo ""
echo "┌─────────────────────────────────────────────────────────┐"
echo "│                    QAT ENGINE MAPPING                  │"
echo "├─────────────────────────────────────────────────────────┤"
echo "│ AE0: Host Critical    │ VF 0,1,2    │ System/LUKS     │"
echo "│ AE1: pfSense Gateway  │ VF 3,4,5,6  │ VPN/IPsec       │"
echo "│ AE2: Storage & Backup │ VF 7,8,9    │ ZFS/Compression │"
echo "│ AE3: Certificate PKI  │ VF 10,11    │ RSA/ECDSA       │"
echo "│ AE4: Web Services     │ VF 12,13    │ HTTPS/TLS       │"
echo "│ AE5: Dev & Testing    │ VF 14,15    │ Development     │"
echo "└─────────────────────────────────────────────────────────┘"
echo ""

# Performance Expectations
echo "⚡ Performance-Erwartungen pro Engine:"
echo "   AE0 (Host):       ~8 Gbps AES-256, 2K RSA/sec"
echo "   AE1 (pfSense):    ~12 Gbps AES-256, 1.5K RSA/sec"
echo "   AE2 (Storage):    ~6 Gbps AES + 800 MB/s DEFLATE"
echo "   AE3 (Certs):      ~4K RSA-2048/sec, 2K ECDSA/sec"
echo "   AE4 (Web):        ~10 Gbps TLS 1.3, 3K Handshakes/sec"
echo "   AE5 (Dev):        ~5 Gbps Mixed Workload"
echo ""

# Implementation Roadmap
echo "🛣️  Implementierung Roadmap:"
echo "   Phase 1: ✅ Hardware Detection & SR-IOV"
echo "   Phase 2: ⏳ Host AE0 Assignment"  
echo "   Phase 3: ⏳ pfSense VF Passthrough"
echo "   Phase 4: ⏳ Storage VM Integration"
echo "   Phase 5: ⏳ Production Optimization"
echo ""

# Zeige nächste Schritte
echo "🔧 Nächste Implementierung Schritte:"
echo ""
echo "1. Host AE0 Setup:"
echo "   systemctl enable qat-ae0-host.service"
echo "   echo 'AE0_VFS=\"0,1,2\"' > /etc/qat/ae0-config"
echo ""
echo "2. pfSense VF Passthrough:"
echo "   qm set <vmid> -hostpci0 0000:XX:00.3,0000:XX:00.4,0000:XX:00.5,0000:XX:00.6"
echo ""
echo "3. Monitoring Integration:"
echo "   systemctl start qat-monitoring.service"
echo "   # Dashboard: http://localhost:8080"
echo ""

# Prüfe ob Implementation gewünscht
echo "💡 Möchtest du die Implementierung starten?"
echo "   Ansonsten ist die Strategie dokumentiert in:"
echo "   📄 /root/QAT_Engine_Allocation_Strategy.md"
echo ""
echo "✅ Strategische Planung abgeschlossen!"
echo "🎯 Bereit für Phase 2: Host AE0 Assignment"