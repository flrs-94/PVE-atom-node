#!/bin/bash
# Failover from Primary (100) to Backup (101) pfSense
# Moves QAT VFs from primary to backup

set -e

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║           pfSense Failover: Primary → Backup                    ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Stop primary
echo "1️⃣  Stopping primary pfSense (VMID 100)..."
qm stop 100
sleep 3

# Remove QAT VFs from primary
echo "2️⃣  Removing QAT VFs from primary..."
qm set 100 --delete hostpci0
qm set 100 --delete hostpci1
qm set 100 --delete hostpci2
qm set 100 --delete hostpci3

# Add QAT VFs to backup
echo "3️⃣  Assigning QAT VFs to backup (VMID 101)..."
qm set 101 \
  --hostpci0 0000:01:01.3,pcie=1 \
  --hostpci1 0000:01:01.4,pcie=1 \
  --hostpci2 0000:01:01.5,pcie=1 \
  --hostpci3 0000:01:01.6,pcie=1

# Start backup
echo "4️⃣  Starting backup pfSense..."
qm start 101
sleep 3

echo ""
echo "✅ Failover complete!"
echo ""
qm status 100
qm status 101
echo ""
echo "Backup pfSense is now active with QAT acceleration!"
