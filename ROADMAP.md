# PVE-atom-node Roadmap

**Entwicklungsplan für das Proxmox VE Gateway-System**

Dieses Dokument beschreibt die Entwicklungsphasen des PVE-atom-node Projekts, von der initialen Hardware-Konfiguration bis zur vollständigen Production-Umgebung mit High Availability.

---

## 📊 Projekt-Übersicht

```
Timeline: Oktober 2025 → Q2 2026
Status: Phase 5 ✅ | Phase 6 🔄 | Phase 7-9 📋
```

---

## Phase 1: Basis-Setup ✅ ABGESCHLOSSEN

**Zeitraum**: Oktober 2025 (Woche 1-2)  
**Status**: ✅ Vollständig implementiert

### Ziele
- Git Repository-Integration
- SSH Deploy Keys
- System-weites Git-Tracking
- Sicherheits-Konfiguration

### Implementierung
- [x] Git Installation und Repository-Verknüpfung
- [x] SSH Deploy Keys für GitHub (`id_ed25519_github`)
- [x] System-weites Git Repository (Root-Level `/`)
- [x] Sicherheits-.gitignore implementiert
- [x] Branch-Strategie etabliert (main, dev)

### Ergebnisse
- Git-basierte Versionsverwaltung aller Configs
- Sichere Authentifizierung ohne Password
- Selective Commits für sensible Daten

**Dokumentation**: `/docs/README.md` (Git Repository Management)

---

## Phase 2: QAT Hardware-Integration ✅ ABGESCHLOSSEN

**Zeitraum**: Oktober 2025 (Woche 2-3)  
**Status**: ✅ Vollständig funktional

### Ziele
- Intel QAT Hardware-Erkennung
- SR-IOV Virtual Functions
- OpenSSL Engine Integration
- Systemd Service-Automatisierung

### Implementierung
- [x] QAT Hardware-Erkennung (`intel_qat`, `qat_c3xxx`)
- [x] Firmware-Status validiert (18 Krypto-Algorithmen)
- [x] SR-IOV mit 16 Virtual Functions aktiviert
- [x] QAT SR-IOV Service (`qat-sriov.service`)
- [x] OpenSSL QAT Engine v2.0.0 konfiguriert
- [x] 6 Acceleration Engines (AE0-AE5) erkannt

### Performance-Ergebnisse
| Algorithmus | CPU-Only | Mit QAT | Speedup |
|-------------|----------|---------|---------|
| AES-256-CBC | ~2 Gbps | ~8 Gbps | **4x** |
| RSA-2048 | ~500/sec | ~2000/sec | **4x** |
| DEFLATE | ~200 MB/s | ~600 MB/s | **3x** |

**Dokumentation**: `/docs/QAT_INTEGRATION_FINAL_REPORT.md`

---

## Phase 3: Netzwerk-Konfiguration ✅ ABGESCHLOSSEN

**Zeitraum**: Oktober 2025 (Woche 3)  
**Status**: ✅ Production-ready

### Ziele
- Persistente Interface-Namen
- SFP+ Passthrough-Vorbereitung
- IOMMU-Gruppierung
- Bridge-Konfiguration

### Implementierung
- [x] 4x Intel X553 SFP+ Ports identifiziert
- [x] IOMMU-Gruppen analysiert (30-33 für SFP+, 34-49 für QAT)
- [x] VFIO-PCI Konfiguration (`/etc/modprobe.d/vfio-pci.conf`)
- [x] Persistente Interface-Namen (udev + systemd)
  - [x] udev Rules mit Priorität 10
  - [x] systemd Network Links als Backup
- [x] Network Bridges konfiguriert
  - [x] vmbr0: LAN (eth5)
  - [x] vmbr1: Storage (eth1)
- [x] Reboot-Tests erfolgreich

### Netzwerk-Architektur
```
┌─────────────────────────────────────────┐
│  Proxmox Host                           │
├─────────────────────────────────────────┤
│  Management: vmbr0 (eth5, 1GbE)         │
│  Storage: vmbr1 (eth1, 1GbE)            │
│                                         │
│  Verfügbar:                             │
│  - eth2, eth3, eth4 (1GbE)              │
│  - sfp6, sfp7 (10GbE, benötigt Module)  │
│  - sfp8 (10GbE, Host)                   │
│  - sfp9 (10GbE, pfSense Passthrough)    │
└─────────────────────────────────────────┘
```

**Dokumentation**: `/config/network/README.md`, `/docs/Interface-Naming-Persistenz.md` (archiviert)

---

## Phase 4: Storage-Architektur ✅ ABGESCHLOSSEN

**Zeitraum**: Oktober 2025 (Woche 3-4)  
**Status**: ✅ Optimiert und getestet

### Ziele
- ZFS Pool Optimierung
- Dedizierte Datasets
- Performance Baseline
- Monitoring Scripts

### Implementierung
- [x] ZFS Pool Konfiguration (rpool, 2x NVMe Mirror)
- [x] Dedizierte Datasets:
  - [x] `rpool/data` - VM Disks (LZ4)
  - [x] `rpool/iso-storage` - ISOs/Templates (LZ4)
  - [x] `rpool/backup` - VM Backups (GZIP-9)
- [x] Proxmox Storage-Integration
  - [x] `vm-disks` → rpool/data
  - [x] `local-isos` → rpool/iso-storage
  - [x] `vm-backups` → rpool/backup
- [x] Performance Benchmarking
- [x] Monitoring Scripts (`zfs-qat-monitor`)

### Performance-Metriken
```
Sequential Read:    1200 MB/s
Sequential Write:   800 MB/s
Random IOPS:        45000 (4K)
Compression Ratio:  2.5x (LZ4)
                    8x (GZIP-9 für Backups)
```

### ZFS + QAT Status
- ❌ Native ZFS QAT Integration nicht verfügbar (Proxmox Limitation)
- ✅ CPU-optimierte Compression (LZ4, GZIP)
- ✅ QAT für VM-Passthrough reserviert (TrueNAS VM)

**Dokumentation**: `/docs/STORAGE-ARCHITECTURE-FINAL.md`, `/docs/ZFS_QAT_SOLUTIONS.md`

---

## Phase 5: Production Readiness ✅ ABGESCHLOSSEN

**Zeitraum**: Oktober 2025 (Woche 4)  
**Status**: ✅ Production-ready

### Ziele
- System-Reboot Tests
- Service-Persistenz
- Umfassende Dokumentation
- Monitoring Dashboard

### Implementierung
- [x] Reboot-Tests durchgeführt (28. Oktober 2025, 10:42 CET)
- [x] Persistenz validiert:
  - [x] QAT SR-IOV: 16 VFs automatisch aktiviert
  - [x] VFIO-Module: korrekt geladen
  - [x] Interface-Namen: persistent über Reboot
- [x] Monitoring Scripts deployed:
  - [x] `/usr/local/bin/qat-status`
  - [x] `/usr/local/bin/sfp-passthrough-status`
  - [x] `/usr/local/bin/pre-reboot-check`
  - [x] `/usr/local/bin/zfs-qat-monitor`
- [x] Dokumentation vervollständigt
- [x] System-Backup erstellt (`/system-backup/`)

### Validation Checklist
- ✅ Hardware Detection (QAT, SFP+)
- ✅ Service Activation (qat-sriov)
- ✅ Network Persistence (interface names)
- ✅ Storage Performance (ZFS benchmarks)
- ✅ Monitoring Tools (alle funktional)

**Dokumentation**: `/docs/README.md`, `/docs/RECOVERY.md`

---

## Phase 6: VM-Erstellung 🔄 IN ARBEIT

**Zeitraum**: November 2025 (Woche 1-2)  
**Status**: 🔄 In Planung

### Ziele
- pfSense VM mit SFP+ Passthrough
- TrueNAS VM mit QAT VF Passthrough
- Basis-VM-Konfigurationen
- Netzwerk-Integration

### Geplante Implementierung

#### pfSense VM (VMID 100)
- [ ] VM-Erstellung (4 Cores, 4GB RAM)
- [ ] SFP+ Hardware-Passthrough (sfp9, 0c:00.1)
- [ ] QAT VF Passthrough (VF 3-6 für AE1)
- [ ] WAN/LAN Bridge-Konfiguration
- [ ] Basis-Firewall Rules
- [ ] VPN-Setup (IPsec/OpenVPN mit QAT)

**Scripts**: `/scripts/create-pfsense-vm.sh`, `/scripts/bind-pfsense-qat-vfs.sh`

#### TrueNAS VM (VMID 200)
- [ ] VM-Erstellung (6 Cores, 8GB RAM)
- [ ] QAT VF Passthrough (VF 7-9 für AE2)
- [ ] Storage Disk Passthrough
- [ ] ZFS Pool mit QAT Acceleration
- [ ] NFS/SMB Shares konfigurieren
- [ ] Backup-Integration

**Scripts**: `/scripts/create-truenas-vm.sh`, `/scripts/bind-truenas-qat-vfs.sh`

#### Backup VM (VMID 150, Optional)
- [ ] Dedizierte Backup-pfSense (Failover)
- [ ] QAT VF Passthrough (VF 10-11)
- [ ] Failover-Scripts
- [ ] Monitoring-Integration

### QAT Allocation Plan
```
AE0 (Host):     VF 0,1,2   → System Critical (SSH, LUKS, TLS)
AE1 (pfSense):  VF 3,4,5,6 → VPN Hardware-Beschleunigung
AE2 (TrueNAS):  VF 7,8,9   → Storage Compression + Encryption
AE3 (Certs):    VF 10,11   → PKI, Let's Encrypt (Zukunft)
AE4 (Web):      VF 12,13   → Web-Services (Zukunft)
AE5 (Dev):      VF 14,15   → Development/Testing (Zukunft)
```

**Dokumentation**: `/docs/TrueNAS_QAT_Setup_Guide.md`, `/docs/VMID Nummerierungs-Schema.md`

---

## Phase 7: Performance-Optimierung 📋 GEPLANT

**Zeitraum**: November 2025 (Woche 3-4)  
**Status**: 📋 Geplant

### Ziele
- QAT Performance-Benchmarks
- Netzwerk-Throughput Tests
- VPN-Beschleunigung messen
- Storage-Compression validieren

### Geplante Tests

#### QAT Crypto Performance
- [ ] pfSense IPsec Throughput (mit/ohne QAT)
- [ ] OpenVPN Performance (mit/ohne QAT)
- [ ] TrueNAS ZFS Compression (mit/ohne QAT)
- [ ] SSL/TLS Handshake-Rate

#### Netzwerk Performance
- [ ] SFP+ Port Throughput (iperf3)
- [ ] Latenz-Messungen (ping, netperf)
- [ ] Multi-Stream Performance
- [ ] Bridge vs. Passthrough Vergleich

#### Storage Benchmarks
- [ ] ZFS Sequential I/O (fio)
- [ ] ZFS Random IOPS (fio)
- [ ] Compression Ratio Tests (verschiedene Datentypen)
- [ ] Snapshot Performance

### Performance-Ziele
```
VPN Throughput:      10+ Gbps (IPsec mit QAT)
Storage Compression: 800+ MB/s (DEFLATE mit QAT)
ZFS I/O:            1200+ MB/s (Sequential)
Network Latency:    < 1ms (Lokal)
```

**Scripts**: `/scripts/qat-performance-test.sh`, `/scripts/host-compression-test.sh`

---

## Phase 8: Advanced Features 📋 GEPLANT

**Zeitraum**: Dezember 2025
**Status**: 📋 Geplant

### Geplante Features

#### High Availability
- [ ] Cluster Setup (3 Nodes)
- [ ] Shared Storage (Ceph/GlusterFS)
- [ ] VM Migration (Live Migration)
- [ ] Automatic Failover
- [ ] Load Balancing

#### Proxmox QAT Plugin
- [ ] Web-UI Integration
- [ ] Real-time QAT Monitoring
- [ ] VF Allocation Management
- [ ] Performance Graphs
- [ ] Alert System

**Components**: `/proxmox-qat-plugin/`, `/qat-dashboard/`

#### Backup-Automatisierung
- [ ] Scheduled VM Backups
- [ ] Incremental Backups
- [ ] Off-site Replication
- [ ] Backup Verification
- [ ] Retention Policies

#### Monitoring Dashboard
- [ ] Grafana Integration
- [ ] Prometheus Metrics
- [ ] QAT Engine Utilization
- [ ] Network Throughput Graphs
- [ ] Storage Performance Metrics

---

## Phase 9: Container & Future 📋 LANGFRISTIG

**Zeitraum**: Q1-Q2 2026
**Status**: 📋 Konzeptphase

### Container-Support
- [ ] LXC mit QAT Integration
- [ ] Docker auf Proxmox
- [ ] Kubernetes Cluster (k3s)
- [ ] QAT Device Plugin für k8s

### Advanced Networking
- [ ] VXLAN für Multi-Site
- [ ] SD-WAN Integration
- [ ] BGP für WAN Failover
- [ ] Advanced QoS

### Security Enhancements
- [ ] Hardware-Security-Module Integration
- [ ] Certificate Authority Automation
- [ ] 2FA für Proxmox
- [ ] Security Scanning

### Experimental
- [ ] QAT für AI/ML Workloads
- [ ] GPU Passthrough für ML
- [ ] Custom Kernel mit QAT Patches
- [ ] ZFS Native QAT Build

---

## 🎯 Aktuelle Prioritäten

### Kurzfristig (November 2025)
1. **pfSense VM erstellen** - Höchste Priorität
2. **TrueNAS VM erstellen** - Hohe Priorität
3. **QAT VF Passthrough testen** - Hohe Priorität
4. **Performance Benchmarks** - Mittel

### Mittelfristig (Dezember 2025)
1. **Proxmox QAT Plugin** - Mittel
2. **Backup-Automatisierung** - Mittel
3. **Monitoring Dashboard** - Niedrig
4. **Dokumentation-Updates** - Laufend

### Langfristig (Q1-Q2 2026)
1. **High Availability** - Niedrig
2. **Container-Support** - Niedrig
3. **Advanced Networking** - Sehr Niedrig

---

## 📊 Erfolgskriterien

### Phase 6 (VM-Erstellung)
- ✅ pfSense VM läuft stabil
- ✅ TrueNAS VM hat QAT-Zugriff
- ✅ SFP+ Passthrough funktioniert
- ✅ Netzwerk-Konnektivität hergestellt

### Phase 7 (Performance)
- ✅ VPN > 10 Gbps mit QAT
- ✅ Storage Compression > 3x Speedup
- ✅ Netzwerk Latenz < 1ms
- ✅ Alle Benchmarks dokumentiert

### Phase 8 (Advanced)
- ✅ QAT Plugin im Web-UI
- ✅ Automatische Backups funktionieren
- ✅ Monitoring Dashboard deployed
- ✅ HA-Cluster getestet

---

## 🔄 Änderungshistorie

| Datum | Phase | Änderung |
|-------|-------|----------|
| 28.10.2025 | Phase 5 | Production Readiness abgeschlossen |
| 28.10.2025 | Phase 4 | Storage-Architektur finalisiert |
| 28.10.2025 | Phase 3 | Netzwerk-Konfiguration abgeschlossen |
| 27.10.2025 | Phase 2 | QAT Hardware-Integration vollständig |
| 26.10.2025 | Phase 1 | Basis-Setup abgeschlossen |
| 29.10.2025 | Roadmap | Repository-Reorganisation durchgeführt |

---

## 📞 Feedback & Fragen

Für Fragen zur Roadmap:
- **GitHub Issues**: Technische Fragen und Bug-Reports
- **GitHub Discussions**: Feature-Requests und allgemeine Diskussionen
- **Pull Requests**: Verbesserungsvorschläge für Roadmap

---

**Letzte Aktualisierung**: 29. Oktober 2025  
**Nächster Review**: 15. November 2025  
**Roadmap Version**: 1.0
