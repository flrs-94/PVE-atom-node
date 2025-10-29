# PVE-atom-node Reproduktionsanleitung

**Schritt-für-Schritt Anleitung zur Reproduktion des Gateway-Systems**

Diese Anleitung ermöglicht es, das komplette PVE-atom-node Gateway-System von Grund auf nachzubauen oder auf neuer Hardware zu replizieren.

---

## 📋 Inhaltsverzeichnis

- [Voraussetzungen](#voraussetzungen)
- [Phase 1: Basis-Installation](#phase-1-basis-installation)
- [Phase 2: QAT-Konfiguration](#phase-2-qat-konfiguration)
- [Phase 3: Netzwerk-Setup](#phase-3-netzwerk-setup)
- [Phase 4: Storage-Konfiguration](#phase-4-storage-konfiguration)
- [Phase 5: Validierung](#phase-5-validierung)
- [Troubleshooting](#troubleshooting)

---

## 🔧 Voraussetzungen

### Hardware-Anforderungen

#### Minimum
- Intel Atom C3000 Serie (oder äquivalent mit QAT Support)
- 8GB RAM
- 2x NVMe/SSD (mindestens 120GB für ZFS Mirror)
- 1x Netzwerk-Interface für Management

#### Empfohlen (wie im Projekt)
- Intel Atom C3758 (8 Cores @ 2.20GHz)
- 16GB RAM oder mehr
- 2x 240GB NVMe (für ZFS Mirror)
- Intel X553 10GbE SFP+ Ports (4x)
- Intel I226-V 1GbE Ports (5x)

### Software-Anforderungen
- Proxmox VE 8.x (getestet mit 8.3.2)
- Linux Kernel >= 5.15
- ZFS 2.2.x oder höher
- Intel QAT Driver >= 1.7.x

### Netzwerk-Zugriff
- Internet-Verbindung für Installation
- SSH-Zugriff zum Server
- Optional: GitHub Account für Repository-Zugriff

---

## Phase 1: Basis-Installation

### 1.1 Proxmox VE Installation

```bash
# 1. Download Proxmox VE ISO
# https://www.proxmox.com/de/downloads

# 2. Boot von ISO und Installation durchführen
# - ZFS RAID1 auswählen für Boot-Disks
# - Hostname: pve-atom-node (oder eigener Name)
# - Domain: local.domain
# - IP-Adresse: Statische IP im Management-Netz
# - Gateway und DNS konfigurieren

# 3. Nach Installation: System aktualisieren
apt update && apt upgrade -y
```

### 1.2 Proxmox Repositories konfigurieren

```bash
# Enterprise Repo deaktivieren (falls keine Subscription)
echo "# deb https://enterprise.proxmox.com/debian/pve bookworm pve-enterprise" > /etc/apt/sources.list.d/pve-enterprise.list

# No-Subscription Repo aktivieren
cat > /etc/apt/sources.list.d/pve-no-subscription.list << EOF
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
EOF

# System aktualisieren
apt update && apt upgrade -y
```

### 1.3 Basis-Tools installieren

```bash
# Wichtige System-Tools
apt install -y \
    git \
    vim \
    htop \
    iotop \
    iperf3 \
    lshw \
    pciutils \
    usbutils \
    net-tools \
    ethtool \
    bridge-utils \
    vlan

# Build-Tools für QAT
apt install -y \
    build-essential \
    linux-headers-$(uname -r) \
    dkms
```

### 1.4 Git Repository klonen

```bash
# SSH Key erstellen (falls nicht vorhanden)
ssh-keygen -t ed25519 -C "pve-atom-node@local" -f /root/.ssh/id_ed25519_github

# Public Key zum GitHub Account hinzufügen
cat /root/.ssh/id_ed25519_github.pub
# → Auf GitHub: Settings → SSH Keys → Add new

# SSH Config erstellen
mkdir -p /root/.ssh
cat > /root/.ssh/config << EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github
    IdentitiesOnly yes
EOF

chmod 600 /root/.ssh/config

# Repository klonen
cd /root
git clone git@github.com:flrs-94/PVE-atom-node.git
cd PVE-atom-node

# Optional: Development Branch
git checkout dev  # Falls vorhanden
```

### 1.5 System-weites Git-Tracking (Optional)

```bash
# Root-Level Git Repository initialisieren
cd /
git init
git config user.name "PVE-atom-node"
git config user.email "root@pve-atom-node.local"

# .gitignore kopieren
cp /root/PVE-atom-node/.gitignore /.gitignore

# Remote hinzufügen (falls gewünscht)
git remote add origin git@github.com:your-username/pve-atom-node-system.git
```

---

## Phase 2: QAT-Konfiguration

### 2.1 QAT Hardware überprüfen

```bash
# QAT Device erkennen
lspci | grep -i quickassist
# Erwartete Ausgabe: 01:00.0 Co-processor: Intel Corporation Atom Processor C3000 Series QuickAssist Technology

# Device Details
lspci -v -s 01:00.0
```

### 2.2 QAT Driver und Libraries installieren

```bash
# Intel QAT Packages installieren
apt install -y \
    qatengine \
    libqat4 \
    qatlib-service \
    intel-qat \
    qat-firmware

# Kernel Module laden
modprobe intel_qat
modprobe qat_c3xxx

# Automatisches Laden bei Boot
cat >> /etc/modules << EOF
intel_qat
qat_c3xxx
vfio
vfio_iommu_type1
vfio_pci
EOF
```

### 2.3 QAT SR-IOV aktivieren

```bash
# SR-IOV Script erstellen
cat > /etc/qat-sriov.sh << 'EOF'
#!/bin/bash
# QAT SR-IOV Aktivierung für 16 Virtual Functions

# Physical Function
PF_PCI="0000:01:00.0"

# SR-IOV aktivieren
echo 16 > /sys/bus/pci/devices/${PF_PCI}/sriov_numvfs

# Status prüfen
VF_COUNT=$(cat /sys/bus/pci/devices/${PF_PCI}/sriov_numvfs)
echo "QAT SR-IOV: ${VF_COUNT} VFs aktiviert"

# VFs auflisten
lspci | grep QuickAssist
EOF

chmod +x /etc/qat-sriov.sh

# Service erstellen
cat > /etc/systemd/system/qat-sriov.service << EOF
[Unit]
Description=Enable Intel QAT SR-IOV
After=multi-user.target
Before=pve-guests.service

[Service]
Type=oneshot
ExecStart=/etc/qat-sriov.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Service aktivieren
systemctl daemon-reload
systemctl enable qat-sriov.service
systemctl start qat-sriov.service

# Status prüfen
systemctl status qat-sriov.service
lspci | grep QuickAssist | wc -l  # Sollte 17 zeigen (1 PF + 16 VFs)
```

### 2.4 OpenSSL QAT Engine konfigurieren

```bash
# Engine-Verfügbarkeit prüfen
openssl engine -t qatengine
# Erwartete Ausgabe: (qatengine) Reference implementation of QAT crypto engine
#                     [ available ]

# QAT OpenSSL Config erstellen
cat > /etc/ssl/openssl-qat.cnf << 'EOF'
openssl_conf = openssl_init

[openssl_init]
engines = engine_section

[engine_section]
qatengine = qatengine_section

[qatengine_section]
engine_id = qatengine
dynamic_path = /usr/lib/x86_64-linux-gnu/engines-3/qatengine.so
default_algorithms = ALL
EOF

# Environment Variable setzen (für Tests)
export OPENSSL_CONF=/etc/ssl/openssl-qat.cnf

# Test
openssl speed -engine qatengine aes-256-cbc
```

### 2.5 Monitoring Scripts installieren

```bash
# Scripts aus Repository kopieren
cd /root/PVE-atom-node
cp system-backup/usr-local-bin/* /usr/local/bin/
chmod +x /usr/local/bin/qat-*
chmod +x /usr/local/bin/sfp-*
chmod +x /usr/local/bin/pre-reboot-check
chmod +x /usr/local/bin/zfs-qat-monitor

# QAT Status prüfen
/usr/local/bin/qat-status
```

---

## Phase 3: Netzwerk-Setup

### 3.1 Hardware erkennen

```bash
# Alle Netzwerk-Interfaces auflisten
ip link show

# PCI-Netzwerk-Devices
lspci | grep -i ethernet
lspci | grep -i network

# Interface MAC-Adressen
ip link | grep -A1 "state"
```

### 3.2 IOMMU aktivieren

```bash
# GRUB Konfiguration bearbeiten
vim /etc/default/grub

# Folgende Parameter zur GRUB_CMDLINE_LINUX_DEFAULT hinzufügen:
# intel_iommu=on iommu=pt

# Beispiel:
# GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"

# GRUB aktualisieren
update-grub

# Reboot erforderlich
reboot
```

### 3.3 IOMMU-Gruppen prüfen (nach Reboot)

```bash
# IOMMU-Gruppen anzeigen
for d in /sys/kernel/iommu_groups/*/devices/*; do
    n=${d#*/iommu_groups/*}; n=${n%%/*}
    printf 'IOMMU Group %s ' "$n"
    lspci -nns "${d##*/}"
done | grep -i "ethernet\|network"

# Erwartete Ausgabe (Beispiel):
# IOMMU Group 30 0b:00.0 Ethernet controller [0200]: Intel Corporation Ethernet Connection X553 [8086:15c4]
# IOMMU Group 31 0b:00.1 Ethernet controller [0200]: Intel Corporation Ethernet Connection X553 [8086:15c4]
# IOMMU Group 32 0c:00.0 Ethernet controller [0200]: Intel Corporation Ethernet Connection X553 [8086:15c4]
# IOMMU Group 33 0c:00.1 Ethernet controller [0200]: Intel Corporation Ethernet Connection X553 [8086:15c4]
```

### 3.4 Persistente Interface-Namen konfigurieren

**Option A: Aus Repository kopieren (empfohlen)**
```bash
cd /root/PVE-atom-node

# udev Rules
cp config/network/10-persistent-net.rules /etc/udev/rules.d/

# systemd Network Links
cp config/network/10-eth*.link /etc/systemd/network/

# udev neu laden
udevadm control --reload-rules
udevadm trigger --subsystem-match=net
```

**Option B: Manuell erstellen**
```bash
# Beispiel: eth1 für 1GbE Port mit MAC 20:7c:14:f7:b2:23
cat > /etc/systemd/network/10-eth1.link << EOF
[Match]
MACAddress=20:7c:14:f7:b2:23

[Link]
Name=eth1
EOF

# Wiederholen für alle Interfaces
# Siehe config/network/10-eth*.link für Beispiele
```

### 3.5 VFIO Passthrough konfigurieren

```bash
# VFIO PCI Config aus Repository
cp /root/PVE-atom-node/config/network/vfio-pci.conf /etc/modprobe.d/

# Alternativ manuell erstellen:
cat > /etc/modprobe.d/vfio-pci.conf << EOF
# VFIO-PCI für SFP+ Passthrough
# Device ID für Intel X553: 8086:15c4

# sfp9 (0c:00.1) für pfSense VM Passthrough
options vfio-pci ids=8086:15c4

# QAT VF Denylist deaktivieren
options vfio-pci disable_denylist=1
EOF

# Blacklist ixgbe für Passthrough-Port (optional)
echo "softdep ixgbe pre: vfio-pci" > /etc/modprobe.d/vfio-ixgbe.conf

# Initramfs aktualisieren
update-initramfs -u -k all

# Reboot erforderlich
reboot
```

### 3.6 Proxmox Network Bridges (nach Reboot)

```bash
# Interfaces-Datei bearbeiten
vim /etc/network/interfaces

# Beispiel-Konfiguration:
cat >> /etc/network/interfaces << 'EOF'

# Management Bridge (LAN)
auto vmbr0
iface vmbr0 inet static
    address 192.168.20.129/24
    gateway 192.168.20.1
    bridge-ports eth5
    bridge-stp off
    bridge-fd 0

# Storage Bridge
auto vmbr1
iface vmbr1 inet manual
    bridge-ports eth1
    bridge-stp off
    bridge-fd 0
EOF

# Netzwerk neu starten
systemctl restart networking

# Oder einzelne Bridge neu starten
ifdown vmbr0 && ifup vmbr0
ifdown vmbr1 && ifup vmbr1
```

### 3.7 Verification

```bash
# Interface-Namen prüfen
ip link show

# Bridges prüfen
brctl show

# VFIO Binding prüfen
lspci -k | grep -A3 X553

# Script aus Repository nutzen
/root/PVE-atom-node/scripts/verify-interface-naming.sh
```

---

## Phase 4: Storage-Konfiguration

### 4.1 ZFS Pool Status prüfen

```bash
# Pools anzeigen
zpool list

# Pool-Status
zpool status

# Root Pool sollte bereits existieren (erstellt bei Installation)
# rpool → ZFS RAID1 aus beiden NVMe Disks
```

### 4.2 Dedizierte ZFS Datasets erstellen

```bash
# VM Disks Dataset (LZ4 Compression)
zfs create -o compression=lz4 \
           -o recordsize=64K \
           -o sync=standard \
           -o atime=off \
           rpool/data

# ISO Storage Dataset (LZ4)
zfs create -o compression=lz4 \
           -o recordsize=128K \
           rpool/iso-storage

# Backup Dataset (Maximum Compression)
zfs create -o compression=gzip-9 \
           -o recordsize=1M \
           -o sync=disabled \
           rpool/backup

# Mountpoints erstellen
mkdir -p /rpool/iso-storage
mkdir -p /rpool/backup

# Datasets mounten
zfs set mountpoint=/rpool/iso-storage rpool/iso-storage
zfs set mountpoint=/rpool/backup rpool/backup
```

### 4.3 Proxmox Storage konfigurieren

```bash
# Storage-Konfiguration bearbeiten
vim /etc/pve/storage.cfg

# Folgende Einträge hinzufügen:

# VM Disks Storage
cat >> /etc/pve/storage.cfg << EOF

zfspool: vm-disks
    pool rpool/data
    sparse
    content images,rootdir

dir: local-isos
    path /rpool/iso-storage
    content iso,vztmpl
    maxfiles 10

dir: vm-backups
    path /rpool/backup
    content backup
    maxfiles 3
EOF

# Oder über Web-UI: Datacenter → Storage → Add
```

### 4.4 ZFS Tuning (Optional)

```bash
# ARC Size limitieren (empfohlen bei < 32GB RAM)
# Beispiel: Max 4GB für ARC
cat >> /etc/modprobe.d/zfs.conf << EOF
options zfs zfs_arc_max=4294967296
EOF

# I/O Scheduler optimieren
cat > /etc/udev/rules.d/60-scheduler.rules << EOF
# Deadline scheduler für NVMe (bessere ZFS Performance)
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
EOF

# Module Parameter prüfen
cat /sys/module/zfs/parameters/zfs_arc_max
```

### 4.5 Performance Baseline

```bash
# ZFS Stats
zpool iostat -v 2

# Compression Ratio
zfs get compressratio rpool/data
zfs get compressratio rpool/backup

# ARC Stats
arc_summary

# Sequential Performance Test (Optional)
dd if=/dev/zero of=/rpool/data/test.img bs=1M count=1024 conv=fdatasync
rm /rpool/data/test.img
```

---

## Phase 5: Validierung

### 5.1 Pre-Reboot Check

```bash
# Umfassende System-Validierung
/usr/local/bin/pre-reboot-check

# Manuelle Checks
systemctl status qat-sriov.service
lspci | grep QuickAssist | wc -l  # Sollte 17 sein
ip link show
zpool status
```

### 5.2 Reboot-Test durchführen

```bash
# System neustarten
reboot

# Nach Reboot validieren:

# 1. QAT SR-IOV
systemctl status qat-sriov.service
lspci | grep QuickAssist | wc -l

# 2. Interface-Namen
ip link show | grep -E "eth[0-9]|sfp[0-9]"

# 3. VFIO Binding
lspci -k -s 0c:00.1 | grep "Kernel driver"
# Sollte zeigen: vfio-pci

# 4. Bridges
brctl show

# 5. ZFS
zpool status
zfs list

# 6. Monitoring
/usr/local/bin/qat-status
/usr/local/bin/sfp-passthrough-status
```

### 5.3 Performance-Tests

```bash
# QAT Engine Test
openssl speed -engine qatengine aes-256-cbc rsa2048

# ZFS Performance
dd if=/dev/zero of=/rpool/data/test bs=1M count=1024 oflag=direct
rm /rpool/data/test

# Network Throughput (benötigt zweiten Server)
# Server 1:
iperf3 -s

# Server 2:
iperf3 -c <server1-ip> -t 30
```

### 5.4 Dokumentation Review

```bash
# System-Info dokumentieren
lshw -short > /root/system-hardware.txt
lspci > /root/system-pci.txt
ip addr > /root/system-network.txt
zpool status > /root/system-zfs.txt

# Ins Repository committen (optional)
cd /root/PVE-atom-node
mkdir -p system-info
cp /root/system-*.txt system-info/
git add system-info/
git commit -m "Add system hardware documentation"
```

---

## 🔧 Troubleshooting

### Problem: QAT VFs nicht verfügbar nach Reboot

**Symptom**: `lspci | grep QuickAssist` zeigt nur 1 Device (PF)

**Lösung**:
```bash
# Service Status prüfen
systemctl status qat-sriov.service

# Manuell aktivieren
/etc/qat-sriov.sh

# Service neu starten
systemctl restart qat-sriov.service

# Log prüfen
journalctl -u qat-sriov.service
```

### Problem: Interface-Namen nicht persistent

**Symptom**: Nach Reboot sind Interfaces nicht mehr eth1, eth2, etc.

**Lösung**:
```bash
# udev Rules prüfen
cat /etc/udev/rules.d/10-persistent-net.rules

# systemd Links prüfen
ls -la /etc/systemd/network/

# udev neu laden
udevadm control --reload-rules
udevadm trigger --subsystem-match=net

# Reboot
reboot
```

### Problem: VFIO Module nicht geladen

**Symptom**: `lsmod | grep vfio` zeigt keine Module

**Lösung**:
```bash
# Module manuell laden
modprobe vfio
modprobe vfio_iommu_type1
modprobe vfio_pci

# /etc/modules prüfen
cat /etc/modules

# Initramfs neu erstellen
update-initramfs -u -k all

# Reboot
reboot
```

### Problem: IOMMU nicht aktiviert

**Symptom**: `/sys/kernel/iommu_groups/` ist leer

**Lösung**:
```bash
# GRUB Config prüfen
cat /etc/default/grub | grep CMDLINE

# Intel IOMMU Parameter sollten vorhanden sein:
# intel_iommu=on iommu=pt

# Falls fehlend:
vim /etc/default/grub
# GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"

update-grub
reboot
```

### Problem: ZFS Pool Performance niedrig

**Symptom**: Langsame I/O-Geschwindigkeit

**Lösung**:
```bash
# ARC Size prüfen
arc_summary | grep "ARC Size"

# I/O Scheduler prüfen
cat /sys/block/nvme0n1/queue/scheduler

# Sollte "none" sein für NVMe
echo none > /sys/block/nvme0n1/queue/scheduler
echo none > /sys/block/nvme1n1/queue/scheduler

# Persistent machen (siehe Phase 4.4)
```

### Problem: OpenSSL QAT Engine nicht verfügbar

**Symptom**: `openssl engine qatengine` zeigt Fehler

**Lösung**:
```bash
# QAT Engine Package prüfen
dpkg -l | grep qat

# Falls nicht installiert:
apt install -y qatengine libqat4

# Engine-Datei prüfen
ls -la /usr/lib/x86_64-linux-gnu/engines-3/qatengine.so

# OpenSSL Version prüfen
openssl version
# Sollte 3.x sein

# Config-Datei prüfen
cat /etc/ssl/openssl-qat.cnf
```

---

## 📝 Checkliste: System bereit für Production

- [ ] Proxmox VE installiert und aktualisiert
- [ ] Git Repository geklont
- [ ] QAT Hardware erkannt (1 PF + 16 VFs)
- [ ] QAT SR-IOV Service aktiv und enabled
- [ ] OpenSSL QAT Engine funktional
- [ ] IOMMU aktiviert und funktional
- [ ] Persistente Interface-Namen konfiguriert
- [ ] VFIO Passthrough konfiguriert
- [ ] Network Bridges erstellt (vmbr0, vmbr1)
- [ ] ZFS Datasets erstellt (data, iso-storage, backup)
- [ ] Proxmox Storage konfiguriert
- [ ] Monitoring Scripts installiert
- [ ] Pre-Reboot Check erfolgreich
- [ ] Reboot-Test bestanden
- [ ] Performance Baseline etabliert
- [ ] Dokumentation aktualisiert

---

## 🎯 Nächste Schritte

Nach erfolgreicher Reproduktion:

1. **VM-Erstellung** - Siehe [ROADMAP.md](ROADMAP.md) Phase 6
2. **QAT VF Passthrough** - VMs QAT Virtual Functions zuweisen
3. **Performance-Tests** - Benchmarks durchführen
4. **Backup-Strategie** - Automatisierung implementieren

Siehe auch:
- [README.md](README.md) - Projekt-Übersicht
- [ROADMAP.md](ROADMAP.md) - Entwicklungsplan
- [docs/](docs/) - Detaillierte Dokumentation

---

**Letzte Aktualisierung**: 29. Oktober 2025  
**Guide Version**: 1.0  
**Getestet auf**: Proxmox VE 8.3.2, Intel Atom C3758
