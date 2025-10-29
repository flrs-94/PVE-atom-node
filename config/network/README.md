# Persistent Network Configuration

This directory contains the persistent network interface naming configuration for the PVE-atom-node.

## Files:

### udev Rules
- `10-persistent-net.rules` - High priority udev rules for interface naming
  - Priority 10 to override Proxmox default rules
  - MAC-based naming for eth0-eth5 (1GbE + USB)
  - PCI KERNELS-based naming for sfp8-sfp9 (10GbE SFP+)

### systemd Network Links
- `10-eth0.link` - USB Ethernet adapter (MAC: 00:e0:4c:30:31:df)
- `10-eth1.link` - 1GbE port 1 (MAC: 20:7c:14:f7:b2:23)
- `10-eth2.link` - 1GbE port 2 (MAC: 20:7c:14:f7:b2:24)
- `10-eth3.link` - 1GbE port 3 (MAC: 20:7c:14:f7:b2:25)
- `10-eth4.link` - 1GbE port 4 (MAC: 20:7c:14:f7:b2:26)
- `10-eth5.link` - 1GbE port 5 (MAC: 20:7c:14:f7:b2:27)

### Network Configuration
- `interfaces` - Proxmox network configuration with bridge assignments

### Kernel Module Configuration
- `vfio-pci.conf` - VFIO PCI passthrough configuration
- `vfio-sfp.conf` - SFP+ interface VFIO configuration
- `ixgbe.conf` - Intel ixgbe driver configuration

## Interface Mapping:

### Working Interfaces:
- `eth0` - USB Ethernet (Realtek RTL8153)
- `eth1-5` - 1GbE Onboard (Intel I226-V)
- `sfp8` - 10GbE SFP+ (Intel X553, 0c:00.0) - Host available
- `sfp9` - 10GbE SFP+ (Intel X553, 0c:00.1) - pfSense passthrough

### Non-functional Interfaces:
- `sfp6` - 10GbE SFP+ (Intel X553, 0b:00.0) - Requires valid SFP+ module
- `sfp7` - 10GbE SFP+ (Intel X553, 0b:00.1) - Requires valid SFP+ module

## Bridge Assignments:
- `vmbr0` - LAN bridge using eth5
- `vmbr1` - Storage bridge using eth1

## Installation:

```bash
# Copy udev rules
sudo cp 10-persistent-net.rules /etc/udev/rules.d/

# Copy systemd link files
sudo cp 10-eth*.link /etc/systemd/network/

# Copy modprobe configurations
sudo cp vfio-*.conf ixgbe.conf /etc/modprobe.d/

# Copy network configuration
sudo cp interfaces /etc/network/

# Reload and apply
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=net
sudo systemctl restart networking
```