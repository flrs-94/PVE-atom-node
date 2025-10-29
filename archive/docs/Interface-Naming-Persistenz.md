# Interface Naming Persistenz - Implementierte Lösung

## Problem
Nach Reboot waren Interface-Namen nicht persistent, da Proxmox eigene udev-Regeln die benutzerdefinierten Regeln überschrieben haben.

## Lösung (Multi-Layer Approach)

### 1. udev-Regeln (Priorität 10)
- **Datei:** `/etc/udev/rules.d/10-persistent-net.rules`
- **Methode:** Hohe Priorität (10 statt 70) um Proxmox-Regeln zu überschreiben
- **Redundanz:** MAC-basiert UND PCI-basiert für mehr Robustheit

### 2. systemd-network Link-Dateien
- **Dateien:** `/etc/systemd/network/10-eth*.link` und `/etc/systemd/network/10-sfp*.link`
- **Methode:** systemd-networkd Interface-Naming (backup zu udev)
- **Vorteil:** Unabhängig von udev, direkte systemd-Integration

### 3. Verifikations-System
- **Script:** `/root/PVE-atom-node/scripts/verify-interface-naming.sh`
- **Service:** `verify-interface-naming.service` (Auto-Start beim Boot)
- **Zweck:** Überwachung und Reporting von Interface-Namen

## Finale Interface-Zuordnung

| Interface | Hardware | MAC-Adresse | Funktion |
|-----------|----------|-------------|----------|
| eth0 | USB Realtek RTL8153 | 00:e0:4c:30:31:df | Backup/Management |
| eth1 | 1GbE Port 1 | 20:7c:14:f7:b2:23 | Storage Bridge (vmbr1) |
| eth2 | 1GbE Port 2 | 20:7c:14:f7:b2:24 | Verfügbar |
| eth3 | 1GbE Port 3 | 20:7c:14:f7:b2:25 | Verfügbar |
| eth4 | 1GbE Port 4 | 20:7c:14:f7:b2:26 | Verfügbar |
| eth5 | 1GbE Port 5 | 20:7c:14:f7:b2:27 | LAN Bridge (vmbr0) |
| sfp6 | SFP+ 0b:00.0 | N/A | Nicht funktional (SFP+ Modul erforderlich) |
| sfp7 | SFP+ 0b:00.1 | N/A | Nicht funktional (SFP+ Modul erforderlich) |
| sfp8 | SFP+ 0c:00.0 | 20:7c:14:f7:b2:2a | Host Storage Network |
| sfp9 | SFP+ 0c:00.1 | 20:7c:14:f7:b2:2b | pfSense WAN Passthrough |

## Bridge-Konfiguration
- **vmbr0:** eth5 (LAN - 192.168.20.129/24)
- **vmbr1:** eth1 (Storage)
- **vmbr2:** Geplant für Client-Netzwerke

## Reboot-Persistenz
✅ **Getestet und bestätigt:**
- udev-Regeln mit Priorität 10 überschreiben Proxmox-Standard
- systemd-network Backup-Naming funktioniert
- Verifikations-Service überwacht Interface-Namen beim Boot
- initramfs enthält alle Konfigurationen

## Wartung
```bash
# Interface-Namen prüfen
/root/PVE-atom-node/scripts/verify-interface-naming.sh

# Service-Status prüfen
systemctl status verify-interface-naming.service

# udev-Regeln neu laden
udevadm control --reload-rules && udevadm trigger --subsystem-match=net
```

**Datum:** $(date)  
**Status:** ✅ Produktionsbereit