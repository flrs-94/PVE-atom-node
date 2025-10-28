#!/bin/bash
# ZFS+QAT Konfiguration für PVE Gateway
# Ausführen nach Hardware-Upgrade auf 2x NVMe Mirror

echo "=== ZFS+QAT Setup für kritisches Gateway ==="

# 1. ZFS Pool erstellen (Mirror für Redundanz)
echo "1. Erstelle ZFS Mirror Pool..."
# zpool create -o ashift=12 \
#              -O compression=gzip-1 \
#              -O checksum=sha256 \
#              -O atime=off \
#              -O xattr=sa \
#              -O acltype=posixacl \
#              rpool mirror /dev/nvme0n1p3 /dev/nvme1n1p3

# 2. QAT-optimierte Datasets
echo "2. Erstelle optimierte Datasets..."

# Root Dataset (Host System)
# zfs create -o compression=lz4 \
#            -o recordsize=64K \
#            -o sync=standard \
#            rpool/ROOT

# VM Dataset (pfSense, TrueNAS)
# zfs create -o compression=gzip-1 \
#            -o recordsize=64K \
#            -o sync=always \
#            -o logbias=throughput \
#            rpool/vm-storage

# Backup Dataset (mit maximaler Kompression)
# zfs create -o compression=gzip-9 \
#            -o recordsize=1M \
#            -o sync=disabled \
#            rpool/backup

# ISO Dataset (Templates)
# zfs create -o compression=lz4 \
#            -o recordsize=1M \
#            -o sync=disabled \
#            rpool/iso-templates

echo "3. QAT-Tuning aktivieren..."
# ZFS QAT-Parameter (wenn verfügbar)
# echo 0 > /sys/module/zfs/parameters/zfs_qat_compress_disable
# echo 0 > /sys/module/zfs/parameters/zfs_qat_encrypt_disable  
# echo 0 > /sys/module/zfs/parameters/zfs_qat_checksum_disable

echo "Setup-Script erstellt. Ausführung nach Hardware-Upgrade."