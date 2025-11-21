# QAT VFIO Passthrough - Denylist Fix

## Problem
Intel QAT C3xxx Virtual Functions (Device ID: 8086:19e3) sind standardmäßig auf der vfio-pci **Denylist/Blacklist**:

```
vfio-pci 0000:01:01.7: 8086:19e3 exists in vfio-pci device denylist
probe with driver vfio-pci failed with error -22
```

## Root Cause
Der Linux Kernel blockt bestimmte Devices aus Sicherheitsgründen. QAT VFs waren historisch problematisch wegen potentieller Exploits bei untrusted Usern.

## Solution

### 1. Kernel Module Parameter setzen
**File:** `/etc/modprobe.d/vfio.conf`
```bash
# Disable vfio-pci denylist to allow Intel QAT VF passthrough
options vfio-pci disable_denylist=1

# Pre-bind QAT VFs for TrueNAS VM
options vfio-pci ids=8086:19e3
```

### 2. Initramfs aktualisieren
```bash
update-initramfs -u -k all
```

### 3. Boot-Time Binding Service
**File:** `/etc/systemd/system/truenas-qat-vfio.service`
```ini
[Unit]
Description=Bind QAT VFs for TrueNAS VM Passthrough
After=qat.service
Before=pve-guests.service

[Service]
Type=oneshot
ExecStart=/root/PVE-atom-node/scripts/bind-truenas-qat-vfs.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

### 4. Binding Script
**File:** `/root/PVE-atom-node/scripts/bind-truenas-qat-vfs.sh`
- Unbindet VFs 7,8,9 von c3xxxvf Driver
- Bindet an vfio-pci mit deaktivierter Denylist
- Wird automatisch beim Boot ausgeführt

## VM Configuration
**TrueNAS VM (VMID 200):**
```
hostpci0: 0000:01:01.7,pcie=1  # QAT VF 7
hostpci1: 0000:01:02.0,pcie=1  # QAT VF 8
hostpci2: 0000:01:02.1,pcie=1  # QAT VF 9
```

## Verification
```bash
# Check VF binding
lspci -k -s 01:01.7
lspci -k -s 01:02.0
lspci -k -s 01:02.1

# Should show: "Kernel driver in use: vfio-pci"

# Check dmesg
dmesg | grep "device denylist disabled"
# Output: vfio-pci: device denylist disabled.
```

## Security Note
⚠️ **Warning:** Deaktivieren der Denylist kann Sicherheitsrisiken bergen, wenn:
- VMs von untrusted Usern betrieben werden
- Devices mit bekannten Exploits durchgereicht werden

In unserem Fall (trusted TrueNAS Storage VM) ist das Risiko akzeptabel.

## Related Issues
- Intel QAT VFs erfordern IOMMU: `intel_iommu=on iommu=pt`
- QAT Engine ist NICHT kompatibel mit Proxmox pveproxy (SSL errors)
- Kernel >= 5.15 erforderlich für moderne VFIO features

## References
- Kernel Documentation: `Documentation/driver-api/vfio-pci-device-specific-driver-acceptance.rst`
- QAT Driver: `/root/QAT.L.4.28.0-00088`
- Allocation Strategy: `docs/QAT_Engine_Allocation_Strategy.md`
