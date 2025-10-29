#!/bin/bash
# Interface naming verification script
# /root/PVE-atom-node/scripts/verify-interface-naming.sh

echo "=== Interface Naming Verification ==="
echo "Date: $(date)"
echo

echo "Expected interfaces:"
echo "eth0  - USB Ethernet (00:e0:4c:30:31:df)"
echo "eth1  - 1GbE (20:7c:14:f7:b2:23)"
echo "eth2  - 1GbE (20:7c:14:f7:b2:24)" 
echo "eth3  - 1GbE (20:7c:14:f7:b2:25)"
echo "eth4  - 1GbE (20:7c:14:f7:b2:26)"
echo "eth5  - 1GbE (20:7c:14:f7:b2:27)"
echo "sfp8  - SFP+ (0c:00.0 - 20:7c:14:f7:b2:2a)"
echo "sfp9  - SFP+ (0c:00.1 - 20:7c:14:f7:b2:2b)"
echo

echo "Current interface status:"
ip -brief link show | grep -E "eth|sfp" | sort

echo
echo "Interface to MAC mapping:"
for iface in eth0 eth1 eth2 eth3 eth4 eth5 sfp8 sfp9; do
    if ip link show $iface >/dev/null 2>&1; then
        mac=$(ip link show $iface | grep "link/ether" | awk '{print $2}')
        echo "$iface: $mac"
    else
        echo "$iface: NOT FOUND"
    fi
done

echo
echo "Verification result:"
missing=0
declare -A expected_macs=(
    ["eth0"]="00:e0:4c:30:31:df"
    ["eth1"]="20:7c:14:f7:b2:23"
    ["eth2"]="20:7c:14:f7:b2:24"
    ["eth3"]="20:7c:14:f7:b2:25"
    ["eth4"]="20:7c:14:f7:b2:26"
    ["eth5"]="20:7c:14:f7:b2:27"
    ["sfp8"]="20:7c:14:f7:b2:2a"
    ["sfp9"]="20:7c:14:f7:b2:2b"
)

for iface in "${!expected_macs[@]}"; do
    expected_mac="${expected_macs[$iface]}"
    if ip link show $iface >/dev/null 2>&1; then
        actual_mac=$(ip link show $iface | grep "link/ether" | awk '{print $2}')
        if [[ "$actual_mac" == "$expected_mac" ]]; then
            echo "✅ $iface correct ($actual_mac)"
        else
            echo "❌ $iface wrong MAC: expected $expected_mac, got $actual_mac"
            missing=$((missing + 1))
        fi
    else
        echo "❌ $iface missing"
        missing=$((missing + 1))
    fi
done

echo
if [[ $missing -eq 0 ]]; then
    echo "🎉 All interfaces correctly named and persistent!"
    exit 0
else
    echo "⚠️  $missing interface(s) need attention"
    exit 1
fi