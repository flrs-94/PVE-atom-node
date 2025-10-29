#!/bin/bash

# Phase 3: pfSense VF Passthrough Setup
# Konfiguriert VF 3,4,5,6 für AE1 (Gateway Critical)

set -e

echo "=== Phase 3: pfSense VF Passthrough Setup ==="
echo "🎯 Ziel: VF 3-6 für pfSense VM (AE1 - Gateway Critical)"
echo ""

# Prüfe Proxmox Installation
if ! command -v qm &> /dev/null; then
    echo "❌ Proxmox qm command nicht gefunden!"
    echo "   Dieses Skript muss auf einem Proxmox VE Host laufen."
    exit 1
fi

echo "✅ Proxmox VE erkannt"
echo ""

# Zeige verfügbare VFs für Passthrough
echo "📊 QAT Virtual Functions für Passthrough:"
echo ""
lspci -nn | grep "QuickAssist.*Virtual" | head -4 | nl -v 3 | while read num line; do
    pci_id=$(echo "$line" | awk '{print $2}')
    echo "   VF ${num}: ${pci_id} → AE1 (pfSense)"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Konfiguration für pfSense VM"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Finde PCI IDs der VFs 3-6
VF3=$(lspci -nn | grep "QuickAssist.*Virtual" | sed -n '4p' | awk '{print $1}')
VF4=$(lspci -nn | grep "QuickAssist.*Virtual" | sed -n '5p' | awk '{print $1}')
VF5=$(lspci -nn | grep "QuickAssist.*Virtual" | sed -n '6p' | awk '{print $1}')
VF6=$(lspci -nn | grep "QuickAssist.*Virtual" | sed -n '7p' | awk '{print $1}')

echo "VF PCI Adressen:"
echo "   VF3: ${VF3}"
echo "   VF4: ${VF4}"
echo "   VF5: ${VF5}"
echo "   VF6: ${VF6}"
echo ""

# Prüfe ob pfSense VM existiert
echo "🔍 Suche pfSense VM..."
PFSENSE_VMID=$(qm list | grep -i pfsense | awk '{print $1}' | head -1)

if [ -z "$PFSENSE_VMID" ]; then
    echo "⚠️  Keine pfSense VM gefunden!"
    echo ""
    echo "📝 VM muss zuerst erstellt werden mit:"
    echo "   • Name: pfSense oder ähnlich"
    echo "   • OS: FreeBSD 14.x"
    echo "   • Netzwerk: Mindestens 2 NICs (WAN + LAN)"
    echo ""
    echo "💡 Manuelle Konfiguration nach VM-Erstellung:"
    echo ""
    echo "qm set <VMID> -hostpci0 ${VF3},pcie=1"
    echo "qm set <VMID> -hostpci1 ${VF4},pcie=1"
    echo "qm set <VMID> -hostpci2 ${VF5},pcie=1"
    echo "qm set <VMID> -hostpci3 ${VF6},pcie=1"
    echo ""
    echo "🎯 Das gibt pfSense 4x QAT VFs für maximale VPN-Performance!"
    exit 0
fi

echo "✅ pfSense VM gefunden: VMID ${PFSENSE_VMID}"
echo ""

# Prüfe ob VM läuft
VM_STATUS=$(qm status ${PFSENSE_VMID} | awk '{print $2}')
if [ "$VM_STATUS" == "running" ]; then
    echo "⚠️  VM läuft gerade - muss gestoppt werden für PCI Passthrough"
    read -p "VM ${PFSENSE_VMID} jetzt stoppen? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        qm stop ${PFSENSE_VMID}
        echo "VM gestoppt"
    else
        echo "Abbruch - stoppe VM manuell und führe Skript erneut aus"
        exit 1
    fi
fi

echo ""
echo "🔧 Konfiguriere PCI Passthrough..."

# IOMMU check
if ! grep -q "intel_iommu=on" /proc/cmdline; then
    echo "⚠️  IOMMU nicht aktiviert in Kernel!"
    echo "   Füge zu /etc/default/grub hinzu: intel_iommu=on iommu=pt"
    echo "   Dann: update-grub && reboot"
    echo ""
fi

# Konfiguriere die 4 VFs für pfSense
echo "Füge VF3 hinzu: ${VF3}"
qm set ${PFSENSE_VMID} -hostpci0 ${VF3},pcie=1

echo "Füge VF4 hinzu: ${VF4}"
qm set ${PFSENSE_VMID} -hostpci1 ${VF4},pcie=1

echo "Füge VF5 hinzu: ${VF5}"
qm set ${PFSENSE_VMID} -hostpci2 ${VF5},pcie=1

echo "Füge VF6 hinzu: ${VF6}"
qm set ${PFSENSE_VMID} -hostpci3 ${VF6},pcie=1

echo ""
echo "✅ PCI Passthrough konfiguriert!"
echo ""

# Zeige VM Config
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Aktuelle VM Konfiguration:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
qm config ${PFSENSE_VMID} | grep hostpci

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Phase 3 Abgeschlossen!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Nächste Schritte:"
echo "   1. Starte pfSense VM: qm start ${PFSENSE_VMID}"
echo "   2. In pfSense: Installiere QAT Engine Package"
echo "   3. Konfiguriere OpenVPN/IPsec mit QAT"
echo "   4. Performance-Tests mit VPN-Traffic"
echo ""
echo "📊 Erwartete Performance:"
echo "   • IPsec: ~2-3 Gbps pro Tunnel (mit QAT)"
echo "   • OpenVPN: ~800 Mbps - 1.2 Gbps (mit QAT)"
echo "   • TLS Handshakes: 3-5x schneller"
echo "   • Gleichzeitige VPN-Clients: 50-100+"
echo ""
echo "🎯 AE1 (pfSense) jetzt bereit mit 4x QAT VFs!"
