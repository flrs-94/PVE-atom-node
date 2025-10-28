# PVE-atom-node Wiederherstellungsanleitung

## 🔄 Komplette Systemwiederherstellung nach ZFS RAID Neuinstallation

### Voraussetzungen
- Frische Proxmox VE Installation
- Zugang zu diesem Repository: `flrs-94/PVE-atom-node`
- SSH-Zugang zum System

### 1. Repository klonen
```bash
cd /root
git clone git@github.com:flrs-94/PVE-atom-node.git
cd PVE-atom-node
git checkout dev
```

### 2. System-Konfigurationen wiederherstellen
```bash
# Modprobe Konfigurationen
cp system-backup/etc-modprobe.d/* /etc/modprobe.d/

# Systemd Services
cp system-backup/etc-systemd/* /etc/systemd/system/

# QAT Startup Script
cp system-backup/scripts/qat-sriov.sh /etc/
chmod +x /etc/qat-sriov.sh

# Custom Scripts
cp system-backup/usr-local-bin/* /usr/local/bin/
chmod +x /usr/local/bin/*

# SSH Konfiguration (falls vorhanden)
mkdir -p /root/.ssh
cp system-backup/ssh-config/config /root/.ssh/ 2>/dev/null || true
```

### 3. Services aktivieren
```bash
# QAT SR-IOV Service
systemctl enable qat-sriov.service

# Module laden bei Boot
echo "vfio" >> /etc/modules
echo "vfio_iommu_type1" >> /etc/modules  
echo "vfio_pci" >> /etc/modules
```

### 4. Hardware validieren
```bash
# Hardware-Check
/usr/local/bin/qat-status
/usr/local/bin/sfp-passthrough-status

# Pre-Reboot Check
/usr/local/bin/pre-reboot-check
```

### 5. Reboot und finale Validierung
```bash
# System neustarten
reboot

# Nach Reboot validieren
/usr/local/bin/pre-reboot-check
```

### 6. VM-Erstellung (nächste Phase)
Nach erfolgreicher Wiederherstellung:
- pfSense VM mit eno4 (0c:00.1) Passthrough + QAT VF
- TrueNAS VM mit Bridge-Netzwerk + QAT VF

### Kritische Dateien in diesem Backup
- **QAT Konfiguration:** `/etc/qat-sriov.sh`, `qat-sriov.service`
- **VFIO Passthrough:** `/etc/modprobe.d/vfio-pci.conf`
- **ZFS QAT Integration:** `/etc/modprobe.d/zfs-qat.conf`
- **Monitoring Scripts:** `/usr/local/bin/qat-*`, `/usr/local/bin/sfp-*`
- **Hardware-Info:** `hardware-info.txt`, `network-interfaces.txt`

### Hardware-Erwartungen
Basierend auf `hardware-info.txt`:
- Intel QAT C3000 Serie (16 VFs)
- Intel X553 SFP+ Controller (4x 10GbE)
- Intel I226-V Controller (5x 1GbE)
- IOMMU Groups 30-33 (SFP+), 34-49 (QAT VFs)

---
**Erstellt:** 28. Oktober 2025  
**System:** PVE-atom-node Gateway  
**Backup-Status:** Vollständig für ZFS RAID Neuinstallation