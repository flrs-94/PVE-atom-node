#!/bin/bash
# Failover from Backup (101) to Primary (100) pfSense
# Moves QAT VFs from backup to primary

set -e

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║           pfSense Failover: Backup → Primary                    ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Stop backup
echo "1️⃣  Stopping backup pfSense (VMID 101)..."
qm stop 101
sleep 3

# Remove QAT VFs from backup
echo "2️⃣  Removing QAT VFs from backup..."
qm set 101 --delete hostpci0 2>/dev/null || true
qm set 101 --delete hostpci1 2>/dev/null || true
qm set 101 --delete hostpci2 2>/dev/null || true
qm set 101 --delete hostpci3 2>/dev/null || true

# Add QAT VFs to primary
echo "3️⃣  Assigning QAT VFs to primary (VMID 100)..."
qm set 100 \
  --hostpci0 0000:01:01.3,pcie=1 \
  --hostpci1 0000:01:01.4,pcie=1 \
  --hostpci2 0000:01:01.5,pcie=1 \
  --hostpci3 0000:01:01.6,pcie=1

# Start primary
echo "4️⃣  Starting primary pfSense..."
qm start 100
sleep 3

echo ""
echo "✅ Failover complete!"
echo ""
qm status 100
qm status 101
echo ""
echo "Primary pfSense is now active with QAT acceleration!"
