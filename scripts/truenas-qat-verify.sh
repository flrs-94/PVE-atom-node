#!/bin/bash
# TrueNAS QAT Verification Script
# Run this inside TrueNAS VM to verify QAT passthrough

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║           TrueNAS QAT Hardware Verification                      ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Check if lspci is available
if ! command -v lspci &> /dev/null; then
    echo "⚠️  lspci not found. Installing pciutils..."
    apt update && apt install -y pciutils
fi

echo "🔍 Searching for Intel QAT devices..."
echo ""

QAT_DEVICES=$(lspci | grep -i "co-processor.*quickassist\|co-processor.*intel.*c3")
QAT_COUNT=$(echo "$QAT_DEVICES" | grep -c "Co-processor" || echo "0")

if [ "$QAT_COUNT" -eq 0 ]; then
    echo "❌ NO QAT devices found!"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check Proxmox host: lspci -k -s 01:01.7"
    echo "  2. Verify VM config: qm config 200 | grep hostpci"
    echo "  3. Check dmesg on host for VFIO errors"
    exit 1
fi

echo "✅ Found $QAT_COUNT QAT Co-Processor(s):"
echo "$QAT_DEVICES"
echo ""

if [ "$QAT_COUNT" -ne 3 ]; then
    echo "⚠️  Expected 3 devices, found $QAT_COUNT"
fi

echo "📋 Detailed device information:"
echo ""
lspci -vv | grep -A 15 "Co-processor.*Intel"
echo ""

echo "�� Checking QAT driver status..."
if [ -c "/dev/qat_adf_ctl" ] || [ -c "/dev/qat_dev_processes" ]; then
    echo "✅ QAT control devices found:"
    ls -la /dev/qat* 2>/dev/null
    echo ""
    echo "✅ QAT driver is loaded!"
else
    echo "⚠️  QAT driver not loaded (devices exist but no /dev/qat*)"
    echo ""
    echo "To load QAT driver:"
    echo "  1. apt install -y linux-headers-\$(uname -r)"
    echo "  2. modprobe qat_c3xxxvf"
    echo "  3. Check: ls -la /dev/qat*"
fi

echo ""
echo "🎯 Kernel modules:"
lsmod | grep qat || echo "  No QAT modules loaded"

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║                    Verification Complete                         ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
