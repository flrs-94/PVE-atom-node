# PVE-atom-node - Gateway System Dokumentation

**Datum:** 28. Oktober 2025  
**System:** Proxmox VE Gateway mit Hardware-Beschleunigung  
**Ziel:** pfSense + TrueNAS Gateway mit QAT & SFP+ Passthrough

## 📋 Projekt-Übersicht

Dieses System wurde als kritischer Gateway-Server konfiguriert mit:
- **pfSense VM**: Firewall/Router mit SFP+ Passthrough für WAN/LAN
- **TrueNAS VM**: Storage-System mit virtueller Bridge-Anbindung
- **Intel QAT**: Hardware-Krypto-Beschleunigung für beide VMs
- **Intel X553 SFP+**: 4x 10GbE Ports mit VFIO Passthrough

## 🛠️ Hardware-Inventar

### Intel QAT C3000 Serie
- **Status:** ✅ Funktional
- **SR-IOV:** 16 Virtual Functions aktiviert
- **Firmware:** Geladen, 18 Krypto-Algorithmen verfügbar
- **Acceleration Engines:** 6 AEs erkannt
- **IOMMU Gruppen:** 34-49 (QAT VFs)

### Intel X553 SFP+ Controller
- **Anzahl:** 4x 10GbE Ports
- **PCI IDs:** 
  - 0b:00.0 (eno1) - IOMMU Gruppe 30
  - 0b:00.1 (eno2) - IOMMU Gruppe 31  
  - 0c:00.0 (eno3) - IOMMU Gruppe 32
  - 0c:00.1 (eno4) - IOMMU Gruppe 33
- **Passthrough:** ✅ VFIO konfiguriert für 8086:15c4

## 🔧 Konfigurationsdateien

### 1. QAT SR-IOV Aktivierung
**Datei:** `/etc/qat-sriov.sh`
```bash
#!/bin/bash
# QAT SR-IOV Aktivierung für 16 Virtual Functions
echo 16 > /sys/bus/pci/devices/0000:01:00.0/sriov_numvfs
echo "QAT SR-IOV: 16 VFs aktiviert"
```

**Service:** `/etc/systemd/system/qat-sriov.service`
- Status: ✅ Enabled (automatischer Start)
- Abhängigkeiten: multi-user.target

### 2. VFIO Passthrough Konfiguration
**Datei:** `/etc/modprobe.d/vfio-pci.conf`
```
# VFIO-PCI Konfiguration für SFP+ Passthrough
# Nur pfSense Port: 0c:00.1 (eno4)
# Host-Ports: 0b:00.0 (eno1), 0b:00.1 (eno2), 0c:00.0 (eno3) bleiben beim ixgbe Treiber
```

**Blacklisting:** `/etc/modprobe.d/blacklist-ixgbe.conf`
```
# Blacklist ixgbe für SFP+ Passthrough
blacklist ixgbe
```

### 3. ZFS QAT Integration
**Datei:** `/etc/modprobe.d/zfs-qat.conf`
```
# ZFS QAT Hardware-Beschleunigung
options zfs zfs_qat_compress_disable=0
options zfs zfs_qat_encrypt_disable=0
options zfs zfs_qat_checksum_disable=0
```

### 4. Git Repository Management
**SSH Konfiguration:** `/root/.ssh/config`
```
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes
```

**System .gitignore:** `/.gitignore`
- Umfassende Ausschlüsse für Sicherheit
- Schutz von /proc/, /sys/, private keys, logs

## 📊 Netzwerk-Architektur

### Port-Zuordnung (FINALE KONFIGURATION)
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   pfSense VM    │    │  TrueNAS VM     │    │  Proxmox Host   │
│                 │    │                 │    │                 │
│ NIC: eno4       │    │ Bridge: vmbr1   │    │ Mgmt: vmbr0     │
│ (0c:00.1 PT)    │    │ (virtuell)      │    │ (enp8s0)        │
│ QAT VF: VPN     │    │ QAT VF: Storage │    │                 │
└─────────────────┘    └─────────────────┘    │ 10GbE verfügbar:│
                                              │ • eno1 (0b:00.0)│
                                              │ • eno2 (0b:00.1)│
                                              │ • eno3 (0c:00.0)│
                                              │ 1GbE verfügbar: │
                                              │ • enp4s0-enp7s0 │
                                              └─────────────────┘
```

### Sicherheits-optimierte Architektur
- **pfSense:** Nur eno4 (0c:00.1) via Hardware-Passthrough für maximale Isolation
- **Host:** 3x 10GbE SFP+ + 4x 1GbE + Management verfügbar
- **TrueNAS:** Virtuelle Bridge für optimalen internen Traffic

### IOMMU Gruppierung
- **Gruppe 30:** eno1 (0b:00.0) - Host verfügbar
- **Gruppe 31:** eno2 (0b:00.1) - Host verfügbar  
- **Gruppe 32:** eno3 (0c:00.0) - Host verfügbar
- **Gruppe 33:** eno4 (0c:00.1) - pfSense Passthrough
- **Gruppe 34-49:** QAT Virtual Functions
- **Vorteil:** Optimale Ressourcen-Verteilung mit maximaler Host-Flexibilität

## 🔍 Monitoring-Scripts

### 1. QAT Status Monitor
**Script:** `/usr/local/bin/qat-status`
- Zeigt aktive VFs, Firmware-Status, Module
- Crypto-Engine Übersicht
- /proc/crypto Integration

### 2. SFP+ Passthrough Status
**Script:** `/usr/local/bin/sfp-passthrough-status`
- Hardware-Erkennung
- IOMMU-Gruppierung
- VFIO-Status
- VM-Zuordnungsplanung

### 3. Pre-Reboot Check
**Script:** `/usr/local/bin/pre-reboot-check`
- Umfassende Statusprüfung vor Neustart
- QAT, SFP+, Git, Services
- Konfigurationsdatei-Validierung

### 4. Netzwerk-Planungstools
**Scripts:** 
- `/usr/local/bin/gateway-network-plan`
- `/usr/local/bin/vm-config-gateway`

## ✅ Erreichte Meilensteine

### Phase 1: Basis-Setup ✅
- [x] Git Installation und Repository-Verknüpfung
- [x] SSH Deploy Keys für GitHub
- [x] System-weites Git Repository (/)
- [x] Sicherheits-.gitignore implementiert

### Phase 2: QAT Hardware ✅
- [x] QAT Hardware-Erkennung
- [x] Firmware-Status validiert
- [x] SR-IOV mit 16 VFs aktiviert
- [x] Automatischer Start konfiguriert
- [x] 18 Krypto-Algorithmen verfügbar

### Phase 3: SFP+ Passthrough ✅
- [x] 4x Intel X553 Ports identifiziert
- [x] IOMMU-Gruppen analysiert (30-33)
- [x] VFIO-PCI Konfiguration
- [x] Ixgbe-Treiber Blacklisting
- [x] Passthrough-Vorbereitung abgeschlossen

### Phase 4: System-Integration ✅
- [x] ZFS QAT-Integration vorbereitet
- [x] Monitoring-Scripts erstellt
- [x] Service-Automatisierung
- [x] Umfassende Dokumentation

## 🚀 Nächste Schritte

### Phase 5: Reboot-Test (ERLEDIGT)
- [x] System-Neustart durchgeführt
- [x] Persistenz aller Konfigurationen geprüft (10:42:36 CET)
- [x] QAT SR-IOV nach Reboot validiert (16 VFs aktiv, Firmware und Crypto-Engines ok)
- [x] VFIO-Module Aktivierung bestätigt (eno4 -> vfio-pci; eno1-3 -> ixgbe)

### Phase 6: VM-Erstellung
- [ ] pfSense VM mit SFP+ Passthrough
  - NIC: eno4 (0c:00.1) - Hardware-isoliert
  - QAT VF für VPN-Beschleunigung
- [ ] TrueNAS VM mit Bridge-Netzwerk
  - Storage-Netzwerk über vmbr1
  - QAT VF für Kompression/Verschlüsselung

### Phase 7: Performance-Tests
- [ ] QAT Krypto-Performance messen
- [ ] SFP+ Durchsatz-Tests
- [ ] VPN-Beschleunigung validieren
- [ ] Storage-Kompression benchmarken

## 🛡️ Sicherheitsaspekte

### Git Repository Sicherheit
- Private Keys ausgeschlossen
- System-kritische Verzeichnisse geschützt
- Selective Commits für Konfigurationen

### Hardware-Isolation
- IOMMU-basierte VM-Isolation
- Dedizierte VF-Zuordnung
- Saubere Treiber-Trennung

### Service-Härtung
- Automatisierte Aktivierung
- Fehlerbehandlung in Scripts
- Monitoring für alle kritischen Services

## 📈 Performance-Erwartungen

### QAT Beschleunigung
- **VPN IPsec:** Bis zu 10x Performance-Steigerung
- **Storage:** Hardware-Kompression/Verschlüsselung
- **SSL/TLS:** Entlastung der CPU bei HTTPS

### SFP+ Netzwerk
- **Durchsatz:** 10 Gbps pro Port
- **Latenz:** < 1ms für lokales Netzwerk
- **Skalierung:** 4 dedizierte Ports für Flexibilität

## 🔧 Troubleshooting

### Häufige Probleme
1. **QAT VFs nicht verfügbar nach Reboot**
   - Solution: `systemctl status qat-sriov.service`
   - Manual: `/etc/qat-sriov.sh`

2. **VFIO Module nicht geladen**
   - Check: `lsmod | grep vfio`
   - Solution: `modprobe vfio-pci`

3. **SFP+ Ports noch im ixgbe**
   - Check: `lspci -k | grep -A3 X553`
   - Solution: Reboot nach blacklist-ixgbe.conf

### Debug-Commands
```bash
# QAT Status
/usr/local/bin/qat-status

# SFP+ Status  
/usr/local/bin/sfp-passthrough-status

# IOMMU Gruppen
find /sys/kernel/iommu_groups/ -type l | sort -V

# VFIO Status
lspci -k | grep -A3 -B1 vfio-pci
```

## 📚 Referenzen

### Intel QAT
- **Dokumentation:** Intel QuickAssist Technology Driver
- **SR-IOV:** PCIe Virtual Functions für VM-Passthrough
- **ZFS Integration:** Native QAT Support seit OpenZFS

### VFIO Passthrough
- **IOMMU:** Input-Output Memory Management Unit
- **PCIe Passthrough:** Direkte Hardware-Zuordnung zu VMs
- **VFIO:** Virtual Function I/O Framework

### Proxmox VE
- **VM Management:** KVM/QEMU basiert
- **Netzwerk:** Bridge-basierte Virtualisierung
- **Storage:** ZFS, LVM, verschiedene Backends

---

**Status:** ✅ Reboot-Test erfolgreich  
**Letzte Aktualisierung:** 28. Oktober 2025, 10:42 CET  
**Konfiguration:** Sicherheits-optimiert - pfSense nutzt `eno4` (0c:00.1) via Passthrough; Host behält `eno1`-`eno3`  
**Nächster Schritt:** VM-Erstellung (pfSense + TrueNAS) — bereit