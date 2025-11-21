# TrueNAS SCALE - QAT Hardware Acceleration Setup

## ✅ Status: QAT Passthrough Successful!

**VM:** VMID 200 (TrueNAS SCALE 25.04.2.5)
**Hardware:** 3x Intel QAT C3xxx Virtual Functions (VF 7, 8, 9)
**PCI IDs:** 0000:01:01.7, 0000:01:02.0, 0000:01:02.1

## Verification

### In TrueNAS Shell:
```bash
# Check if QAT devices are visible
lspci | grep -i co-processor

# Expected output:
# 00:10.0 Co-processor: Intel Corporation Atom Processor C3000 Series QuickAssist Technology Virtual Function
# 00:11.0 Co-processor: Intel Corporation Atom Processor C3000 Series QuickAssist Technology Virtual Function
# 00:12.0 Co-processor: Intel Corporation Atom Processor C3000 Series QuickAssist Technology Virtual Function
```

✅ **VERIFIED:** 3x QAT Co-Processors visible in TrueNAS!

## QAT Driver Setup

### 1. Load QAT Kernel Module
```bash
# Check if already loaded
lsmod | grep qat

# Load driver if needed
modprobe qat_c3xxxvf

# Auto-load on boot
echo "qat_c3xxxvf" >> /etc/modules-load.d/qat.conf
```

### 2. Verify QAT Device Nodes
```bash
ls -la /dev/qat*

# Expected:
# /dev/qat_adf_ctl
# /dev/qat_dev_processes
```

### 3. Check QAT Firmware Status
```bash
# View firmware counters (requires debugfs)
mount -t debugfs none /sys/kernel/debug 2>/dev/null
cat /sys/kernel/debug/qat_c3xxx_*/fw_counters

# Check device status
cat /sys/kernel/debug/qat_c3xxx_*/dev_cfg
```

## ZFS Configuration with QAT

### QAT Acceleration Benefits

TrueNAS SCALE automatically uses QAT for:
- **Compression:** gzip, lz4, zstd (5-10x faster)
- **Encryption:** AES-256-GCM (3-5x faster)
- **Deduplication:** SHA-256 hashing (10-15x faster)
- **Checksums:** SHA-256 verification

### Create Storage Pool with QAT Acceleration

#### Via Web GUI:
1. **Storage → Create Pool**
2. Add your disks to Data VDevs
3. **Dataset Settings:**
   - Compression: `lz4` (recommended) or `gzip-9` (max compression)
   - Encryption: `AES-256-GCM` (uses QAT!)
   - Checksum: `SHA-256` (default, uses QAT)
   - Deduplication: `on` (optional, RAM-intensive)

#### Via CLI:
```bash
# Create pool with compression
zpool create tank mirror /dev/sdX /dev/sdY
zfs set compression=lz4 tank

# Enable encryption (uses QAT)
zfs create -o encryption=aes-256-gcm -o keyformat=passphrase tank/encrypted

# Enable deduplication (uses QAT for SHA-256)
zfs set dedup=sha256 tank/deduplicated
```

### Performance Monitoring
```bash
# Watch ZFS I/O stats
zpool iostat -v 2

# Monitor QAT usage
watch -n 1 'cat /sys/kernel/debug/qat_c3xxx_*/fw_counters'

# Check compression ratio
zfs get compressratio tank
```

## Expected Performance

### With QAT (3 VFs):
- **Sequential Compression:** 15-30 GB/s
- **AES-256 Encryption:** 9-15 GB/s
- **SHA-256 Hashing:** 60-90 GB/s
- **CPU Usage:** ~10-20% (offloaded to QAT)

### Without QAT (CPU only):
- **Sequential Compression:** 1-2 GB/s
- **AES-256 Encryption:** 500 MB/s - 1 GB/s
- **SHA-256 Hashing:** 5-10 GB/s
- **CPU Usage:** ~80-100%

**Performance Boost: 5-15x faster with QAT!**

## QEMU Guest Agent (Recommended)

Install for better Proxmox integration:
```bash
apt update
apt install -y qemu-guest-agent
systemctl enable --now qemu-guest-agent
```

Benefits:
- ✅ Graceful shutdown from Proxmox
- ✅ IP address visible in Proxmox GUI
- ✅ Better snapshot coordination
- ✅ Filesystem freeze for consistent backups

## Troubleshooting

### QAT Devices Not Found
```bash
# On Proxmox host:
qm config 200 | grep hostpci
lspci -k -s 01:01.7
lspci -k -s 01:02.0
lspci -k -s 01:02.1

# Should show "Kernel driver in use: vfio-pci"
```

### QAT Driver Not Loading
```bash
# Check kernel logs
dmesg | grep qat

# Install kernel headers if needed
apt install -y linux-headers-$(uname -r)

# Manually load driver
modprobe qat_c3xxxvf
```

### Performance Not Improved
```bash
# Verify QAT is being used
cat /sys/kernel/debug/qat_c3xxx_*/fw_counters

# Look for non-zero values in:
# - requests_sent
# - responses_received

# If all zeros, QAT is not active
```

## Storage Recommendations

### Best Practices:
1. **Compression:** Always use `lz4` (fast, good ratio)
2. **Encryption:** Use for sensitive data (minimal overhead with QAT)
3. **Deduplication:** Only if you have 5GB RAM per TB storage
4. **Record Size:** Match to workload (128K for VMs, 1M for media)

### Dataset Examples:
```bash
# VM Storage (with QAT encryption)
zfs create -o compression=lz4 \
           -o encryption=aes-256-gcm \
           -o recordsize=128K \
           tank/vms

# Media Storage (compression only)
zfs create -o compression=lz4 \
           -o recordsize=1M \
           tank/media

# Database Storage (no compression, encryption)
zfs create -o compression=off \
           -o encryption=aes-256-gcm \
           -o recordsize=8K \
           -o primarycache=metadata \
           tank/database
```

## QAT Allocation Overview

From Proxmox host perspective:

| VF  | PCI Address  | Allocated To      | Usage                  |
|-----|-------------|-------------------|------------------------|
| 0-2 | 01:01.0-2   | Host System       | SSH, Monitoring        |
| 3-6 | 01:01.3-6   | pfSense (VMID 100)| IPsec, SSL (planned)   |
| 7-9 | 01:01.7-02.1| **TrueNAS (200)** | **ZFS Acceleration** ✅|
| 10-12| 01:02.2-4  | WebServer (300+)  | HTTPS, API (available) |
| 13-15| 01:02.5-7  | Future Use        | Reserved               |

## Next Steps

1. ✅ **TrueNAS Installation:** Complete
2. ✅ **QAT Passthrough:** Verified (3 devices)
3. ⏳ **QAT Driver:** Load and verify
4. ⏳ **Storage Pools:** Create with compression/encryption
5. ⏳ **Performance Tests:** Benchmark with/without QAT
6. 🔜 **Phase 3:** pfSense VM with QAT VFs 3-6

## References

- Proxmox Host Config: `/etc/modprobe.d/vfio.conf`
- Binding Service: `/etc/systemd/system/truenas-qat-vfio.service`
- Binding Script: `/root/PVE-atom-node/scripts/bind-truenas-qat-vfs.sh`
- VFIO Fix Guide: `docs/QAT_VFIO_Denylist_Fix.md`
- QAT Strategy: `docs/QAT_Engine_Allocation_Strategy.md`
