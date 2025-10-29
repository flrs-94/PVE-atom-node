#!/bin/bash
# Bind QAT VFs 7,8,9 to vfio-pci for TrueNAS VM passthrough
# This script is called by systemd service on boot

VFS=("0000:01:01.7" "0000:01:02.0" "0000:01:02.1")

echo "Binding QAT VFs to vfio-pci for TrueNAS VM..."

# Ensure vfio-pci module is loaded with denylist disabled
modprobe -r vfio-pci 2>/dev/null
modprobe vfio-pci disable_denylist=1 ids=8086:19e3

sleep 2

for vf in "${VFS[@]}"; do
    echo "Processing $vf..."
    
    # Unbind from c3xxxvf if bound
    if [ -e "/sys/bus/pci/drivers/c3xxxvf/$vf" ]; then
        echo "$vf" > /sys/bus/pci/drivers/c3xxxvf/unbind
        echo "  Unbound from c3xxxvf"
    fi
    
    # Add to vfio-pci new_id if needed
    if ! lspci -k -s "${vf#0000:}" | grep -q "vfio-pci"; then
        echo "8086 19e3" > /sys/bus/pci/drivers/vfio-pci/new_id 2>/dev/null || true
    fi
    
    # Bind to vfio-pci
    if [ ! -e "/sys/bus/pci/drivers/vfio-pci/$vf" ]; then
        echo "$vf" > /sys/bus/pci/drivers/vfio-pci/bind 2>/dev/null && \
            echo "  Bound to vfio-pci" || \
            echo "  Already bound or failed"
    else
        echo "  Already bound to vfio-pci"
    fi
done

echo "QAT VF binding complete!"
lspci -k -s 01:01.7 | grep "Kernel driver"
lspci -k -s 01:02.0 | grep "Kernel driver"
lspci -k -s 01:02.1 | grep "Kernel driver"
