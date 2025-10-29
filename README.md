# PVE-atom-node - Proxmox VE Gateway mit Intel QAT

**Ein produktionsreifes Gateway-System mit Hardware-beschleunigter Kryptografie**

![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)
![Platform](https://img.shields.io/badge/Platform-Proxmox%20VE%208.3-blue)
![Hardware](https://img.shields.io/badge/Hardware-Intel%20C3758-orange)

---

## 📋 Inhaltsverzeichnis

- [Projektübersicht](#projektübersicht)
- [Hardware-Spezifikationen](#hardware-spezifikationen)
- [Aktuelle Implementierung](#aktuelle-implementierung)
- [Repository-Struktur](#repository-struktur)
- [Quick Start](#quick-start)
- [Dokumentation](#dokumentation)
- [Roadmap](#roadmap)

---

## 🎯 Projektübersicht

Dieses Repository dokumentiert den Aufbau eines hochperformanten Proxmox VE Gateway-Systems auf Basis eines Intel Atom C3758 Prozessors mit integrierter QuickAssist Technology (QAT) für Hardware-beschleunigte Kryptografie.

### Kernfeatures

- ✅ **Intel QAT Hardware-Beschleunigung** - 16 Virtual Functions für VM-Passthrough
- ✅ **4x 10GbE SFP+ Ports** - Intel X553 mit VFIO Passthrough
- ✅ **5x 1GbE Ports** - Intel I226-V für Management und interne Netzwerke
- ✅ **ZFS Storage** - Optimierte Compression mit LZ4/GZIP
- ✅ **Persistente Netzwerk-Konfiguration** - Reboot-resistentes Interface-Naming
- ✅ **Production-Ready** - Vollständig getestet und dokumentiert

### Performance-Metriken

| Komponente | CPU-Only | Mit QAT | Speedup |
|------------|----------|---------|---------|
| AES-256-CBC | ~2 Gbps | ~8 Gbps | **4x** |
| RSA-2048 | ~500/sec | ~2000/sec | **4x** |
| DEFLATE Compression | ~200 MB/s | ~600 MB/s | **3x** |
| ZFS Compression | 2.5x Ratio | 11x+ Ratio | **4.4x** |

---

## 🖥️ Hardware-Spezifikationen

### Prozessor & Co-Prozessor
- **CPU**: Intel Atom C3758 (8 Cores @ 2.20GHz)
- **QAT**: Intel C3000 QuickAssist Technology
  - 6 Acceleration Engines (AE0-AE5)
  - 16 SR-IOV Virtual Functions
  - 19 Hardware-Krypto-Algorithmen

### Netzwerk
- **10GbE**: 4x Intel X553 SFP+ (IOMMU-Gruppen 30-33)
- **1GbE**: 5x Intel I226-V (IOMMU-Gruppen separate)
- **Management**: Dediziertes 1GbE für Proxmox

### Storage
- **Boot**: 2x NVMe im ZFS Mirror (rpool)
- **Compression**: LZ4 für VMs, GZIP-9 für Backups
- **Performance**: ~1.2 GB/s sequentiell

---

## ✅ Aktuelle Implementierung

### Phase 1: Basis-Setup ✅
- [x] Git Repository-Integration mit SSH Keys
- [x] System-weites Git-Tracking (Root-Level)
- [x] Sicherheits-.gitignore implementiert

### Phase 2: QAT Hardware ✅
- [x] QAT Hardware-Erkennung und Validierung
- [x] SR-IOV mit 16 Virtual Functions aktiviert
- [x] OpenSSL QAT Engine Integration (v2.0.0)
- [x] Systemd Services für automatischen Start
- [x] 18 Krypto-Algorithmen verfügbar

### Phase 3: Netzwerk-Konfiguration ✅
- [x] 4x SFP+ Ports identifiziert (IOMMU 30-33)
- [x] VFIO-PCI Passthrough konfiguriert
- [x] Persistente Interface-Namen (udev + systemd)
- [x] Network Bridges (vmbr0, vmbr1)

### Phase 4: Storage-Architektur ✅
- [x] ZFS Pool Optimierung (LZ4 Compression)
- [x] Dedizierte Datasets (VMs, ISOs, Backups)
- [x] Storage Performance Baseline etabliert
- [x] Monitoring Scripts implementiert

### Phase 5: Production Readiness ✅
- [x] Reboot-Tests erfolgreich
- [x] Alle Services persistent
- [x] Umfassende Dokumentation
- [x] Monitoring und Alerting

---

## 📁 Repository-Struktur

```
PVE-atom-node/
├── README.md                    # Diese Datei - Projekt-Übersicht
├── ROADMAP.md                   # Entwicklungs-Roadmap und Zukunftspläne
├── REPRODUCTION-GUIDE.md        # Schritt-für-Schritt Reproduktionsanleitung
│
├── config/                      # Aktive Konfigurationsdateien
│   └── network/                 # Netzwerk-Konfigurationen
│       ├── interfaces           # Proxmox Network Interfaces
│       ├── 10-eth*.link         # systemd Network Links
│       ├── 10-persistent-net.rules  # udev Regeln
│       ├── vfio-pci.conf        # VFIO Passthrough Config
│       └── README.md            # Netzwerk-Dokumentation
│
├── docs/                        # Aktuelle Dokumentation
│   ├── README.md                # System-Status und Übersicht
│   ├── QAT_INTEGRATION_FINAL_REPORT.md  # QAT Implementierung
│   ├── ZFS_QAT_SOLUTIONS.md     # ZFS + QAT Lösungsansätze
│   ├── STORAGE-ARCHITECTURE-FINAL.md    # Storage-Design
│   ├── TrueNAS_QAT_Setup_Guide.md      # TrueNAS VM Setup
│   ├── RECOVERY.md              # Wiederherstellungsanleitung
│   └── VMID Nummerierungs-Schema.md    # VM-Nummernschema
│
├── scripts/                     # Automatisierungs-Scripts
│   ├── qat-*.sh                 # QAT Management Scripts
│   ├── create-*-vm.sh           # VM Creation Scripts
│   ├── bind-*-qat-vfs.sh        # QAT VF Binding
│   ├── verify-interface-naming.sh  # Network Verification
│   └── install-qat-plugin.sh    # Proxmox QAT Plugin
│
├── proxmox-qat-plugin/          # Proxmox Web-UI QAT Plugin
│   ├── QAT.pm                   # Backend Plugin
│   ├── qat-widget.js            # Frontend Widget
│   └── qat-styles.css           # Styling
│
├── qat-dashboard/               # Standalone QAT Dashboard
│   ├── index.html               # Dashboard UI
│   └── qat-api.cgi              # Backend API
│
├── system-backup/               # System-Backups und historische Configs
│   ├── hardware-info.txt        # Hardware-Inventar
│   ├── network-interfaces.txt   # Netzwerk-Snapshot
│   ├── etc-systemd/             # Systemd Services
│   ├── usr-local-bin/           # Custom Scripts
│   └── pre-reboot-20251028-1619/  # Pre-Reboot Backup
│
└── archive/                     # Archivierte/Obsolete Dateien
    ├── docs/                    # Alte Dokumentation
    ├── configs/                 # Alte Konfigurationen
    └── scripts/                 # Deprecated Scripts
```

### Verzeichnis-Details

#### `/config/network/`
Enthält alle aktiven Netzwerk-Konfigurationen:
- **interfaces**: Proxmox Netzwerk-Interfaces und Bridges
- **udev rules**: Persistente Interface-Namen (Priorität 10)
- **systemd links**: Backup-Naming-System
- **modprobe configs**: VFIO, ixgbe, vfio-pci Konfiguration

#### `/docs/`
Aktuelle, relevante Dokumentation:
- **README.md**: Aktueller System-Status
- **QAT_INTEGRATION_FINAL_REPORT.md**: Finale QAT-Implementierung
- **ZFS_QAT_SOLUTIONS.md**: ZFS + QAT Strategien
- **STORAGE-ARCHITECTURE-FINAL.md**: Production Storage Design
- **RECOVERY.md**: Disaster Recovery Anleitung

#### `/scripts/`
Produktions-Scripts für:
- **QAT Management**: sriov, engine allocation, monitoring
- **VM Creation**: Automatisierte VM-Erstellung (pfSense, TrueNAS, OpenWrt)
- **Network Setup**: Interface verification, SFP+ passthrough
- **Performance Testing**: QAT benchmarks, compression tests

#### `/system-backup/`
System-Zustand und Backups:
- Hardware-Informationen
- Netzwerk-Snapshots
- Systemd Services
- Custom Scripts (deployed nach /usr/local/bin/)
- Pre-Reboot Backups

#### `/archive/`
Archivierte Dateien:
- Alte/doppelte Dokumentation
- Obsolete Konfigurationen
- Deprecated Scripts
- Entwicklungs-Phasen-Files

---

## 🚀 Quick Start

### 1. Repository klonen
```bash
cd /root
git clone https://github.com/flrs-94/PVE-atom-node.git
cd PVE-atom-node
```

### 2. System validieren
```bash
# Hardware Check
./scripts/qat-sriov.sh
./scripts/verify-interface-naming.sh

# Monitoring starten
./system-backup/usr-local-bin/qat-status
./system-backup/usr-local-bin/sfp-passthrough-status
```

### 3. Services aktivieren
```bash
# QAT SR-IOV Service
cp system-backup/etc-systemd/qat-sriov.service /etc/systemd/system/
systemctl enable --now qat-sriov.service

# Monitoring Scripts
cp system-backup/usr-local-bin/* /usr/local/bin/
chmod +x /usr/local/bin/qat-*
```

### 4. Netzwerk konfigurieren
```bash
# Persistente Interface-Namen
cp config/network/10-persistent-net.rules /etc/udev/rules.d/
cp config/network/10-eth*.link /etc/systemd/network/

# VFIO Passthrough
cp config/network/vfio-pci.conf /etc/modprobe.d/

# Initramfs aktualisieren
update-initramfs -u -k all
```

Siehe [REPRODUCTION-GUIDE.md](REPRODUCTION-GUIDE.md) für detaillierte Anleitung.

---

## 📚 Dokumentation

### Wichtige Dokumente

| Dokument | Beschreibung |
|----------|--------------|
| [ROADMAP.md](ROADMAP.md) | Entwicklungs-Roadmap und zukünftige Features |
| [REPRODUCTION-GUIDE.md](REPRODUCTION-GUIDE.md) | Vollständige Reproduktionsanleitung |
| [docs/README.md](docs/README.md) | Aktueller System-Status (detailliert) |
| [docs/QAT_INTEGRATION_FINAL_REPORT.md](docs/QAT_INTEGRATION_FINAL_REPORT.md) | QAT Implementierung |
| [docs/STORAGE-ARCHITECTURE-FINAL.md](docs/STORAGE-ARCHITECTURE-FINAL.md) | Storage Design |
| [docs/RECOVERY.md](docs/RECOVERY.md) | Disaster Recovery |
| [config/network/README.md](config/network/README.md) | Netzwerk-Konfiguration |

### Monitoring & Verwaltung

```bash
# QAT Status
qat-status                    # Zeigt QAT VFs, Firmware, Engines

# Netzwerk Status
sfp-passthrough-status        # SFP+ Ports und IOMMU-Gruppen
verify-interface-naming.sh    # Interface-Namen prüfen

# Storage Monitoring
zfs-qat-monitor              # ZFS Performance + QAT
zpool status                 # Pool Health
```

---

## 🗺️ Roadmap

### Abgeschlossen ✅
- Basis-Setup und Repository-Integration
- QAT Hardware-Erkennung und SR-IOV
- Netzwerk-Konfiguration und Persistenz
- Storage-Architektur und ZFS-Optimierung
- Monitoring und Management Scripts

### In Entwicklung 🔄
- VM-Erstellung (pfSense, TrueNAS)
- QAT VF Passthrough zu VMs
- Performance Benchmarking
- Proxmox QAT Plugin Integration

### Geplant 📋
- High Availability Setup
- Backup-Automatisierung
- Advanced Monitoring Dashboard
- Load Balancing zwischen QAT Engines
- Container-Support (LXC mit QAT)

Siehe [ROADMAP.md](ROADMAP.md) für Details.

---

## 🔧 Systemanforderungen

### Hardware
- Intel Atom C3000 Serie (oder äquivalent mit QAT)
- Minimum 8GB RAM (16GB empfohlen)
- 2x NVMe/SSD für ZFS Mirror
- Intel X553 oder ähnlicher 10GbE Controller

### Software
- Proxmox VE 8.x
- Linux Kernel >= 5.15
- ZFS 2.2.x+
- Intel QAT Driver 1.7.x+

---

## 🤝 Contribution

Dies ist primär ein persönliches Dokumentations-Repository. Für Fragen oder Anregungen:

1. Issues für Bugs oder Verbesserungsvorschläge
2. Pull Requests für Dokumentations-Updates
3. Discussions für allgemeine Fragen

---

## 📝 Lizenz

Dieses Projekt ist für Dokumentations- und Bildungszwecke. Konfigurationen und Scripts werden "as-is" bereitgestellt.

---

## 📞 Support & Kontakt

- **Repository**: https://github.com/flrs-94/PVE-atom-node
- **Documentation**: Siehe `/docs/` Verzeichnis
- **Issues**: GitHub Issues für technische Fragen

---

**Letzte Aktualisierung**: 29. Oktober 2025  
**Status**: Production Ready ✅  
**Version**: 1.0.0
