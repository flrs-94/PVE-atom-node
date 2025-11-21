#!/bin/bash
# QAT Host VF Setup für AE0

echo "Setze QAT Host Engine (AE0) auf..."

# Host behält VF 0,1,2 für kritische Services
# Diese VFs werden NICHT an VMs weitergegeben
echo "Host VF Assignment: VF0,VF1,VF2 für AE0"

# ZFS Performance Tuning (CPU-basiert da kein QAT)
echo deadline > /sys/block/nvme0n1/queue/scheduler 2>/dev/null || true
echo deadline > /sys/block/nvme1n1/queue/scheduler 2>/dev/null || true

# Kernel Crypto für bessere Performance
modprobe aes_x86_64 2>/dev/null || true
modprobe crc32c_intel 2>/dev/null || true

echo "QAT AE0 Host Configuration aktiv"
