# OpenWRT LXC Implementation

## Overview
OpenWRT running in an LXC container provides a lightweight alternative to the VM implementation with lower resource overhead and better performance.

## Privileged vs Unprivileged Container

### Why Privileged is Required
OpenWRT requires privileged LXC container due to:
- **Network interface management** - Creating/modifying bridges, VLANs
- **Kernel module loading** - iptables, bridge, netfilter modules
- **Device access** - /dev/net/tun, /dev/net/tap for VPN functionality
- **Raw socket operations** - Required for routing protocols
- **System-level network configuration** - Routing tables, firewall rules

### Unprivileged Alternative (Not Recommended)
Theoretically possible but impractical:
```bash
# LXC config additions needed:
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.cap.keep: net_admin net_raw sys_module
# Custom AppArmor profile required
```
**Problem:** Security isolation lost defeats unprivileged purpose.

## Testing

### Development Branch Testing
```bash
# From checked out feature branch - set REPO variable
REPO="mcgarrah/ProxmoxVE/feature/openwrt-lxc" bash ct/openwrt-lxc.sh

# To skip VAAPI prompts
export var_vaapi="0"
export var_hwaccel="0"
REPO="mcgarrah/ProxmoxVE/feature/openwrt-lxc" bash ct/openwrt-lxc.sh
```

### Production Testing
```bash
# From upstream main branch
bash ct/openwrt-lxc.sh
```

## Access Methods
- **Web UI:** `http://<container-ip>`
- **Container Shell:** `pct enter <container-id>`
- **OpenWRT Shell:** `openwrt <command>`
- **Aliases:** `owrt`, `luci`

## TODO Items

### High Priority
- [ ] Test OpenWRT package installation (opkg)
- [ ] Verify network interface passthrough
- [ ] Test VPN functionality (WireGuard/OpenVPN)
- [ ] Validate firewall rules work correctly
- [ ] Test backup/restore functionality

### Medium Priority
- [ ] Add support for multiple OpenWRT versions
- [ ] Implement custom network configuration options
- [ ] Add VLAN configuration support
- [ ] Create update mechanism for OpenWRT packages
- [ ] Add monitoring/logging integration

### Low Priority
- [ ] Performance benchmarking vs VM
- [ ] Documentation for advanced configurations
- [ ] Integration with Proxmox SDN
- [ ] Custom package repository support

### Known Issues
- [ ] Investigate chroot environment stability
- [ ] Verify all OpenWRT services start correctly
- [ ] Test container migration compatibility
- [ ] Validate resource limits work properly

## FAQ

### Why Debian + OpenWRT chroot instead of pure OpenWRT container?
- **Debian base:** Provides systemd, package management, stability
- **OpenWRT chroot:** Gives full OpenWRT functionality and UCI config
- **Best of both:** Container management + router capabilities
- **Intel rootfs:** Uses x86_64 OpenWRT build optimized for virtualization

## Architecture Notes
- **Base:** Debian 12 LXC container (provides systemd, package management)
- **OpenWRT:** Intel x86_64 rootfs runs in chroot at `/opt/openwrt`
- **Hybrid approach:** Debian host + OpenWRT chroot for best of both worlds
- **Management:** systemd service controls OpenWRT lifecycle
- **Network:** Default LAN 192.168.1.1/24, configurable via UCI
- **Hardware acceleration:** Disabled (network-only container)

## Alternative: Native OpenWRT Template

### Creating Pure OpenWRT LXC Template
For better compatibility and smaller footprint, create a native OpenWRT template:

```bash
# Download OpenWRT rootfs
wget https://downloads.openwrt.org/releases/23.05.5/targets/x86/64/openwrt-23.05.5-x86-64-rootfs.tar.gz

# Extract and repackage as LXC template
mkdir openwrt-rootfs
tar -xzf openwrt-23.05.5-x86-64-rootfs.tar.gz -C openwrt-rootfs
cd openwrt-rootfs

# Create LXC template
tar -czf ../openwrt-23.05.5-lxc_amd64.tar.gz .
```

### Hosting Options
- **GitHub Releases:** Upload to repository releases
- **Proxmox local:** Copy to `/var/lib/vz/template/cache/`
- **Web server:** Any HTTP accessible location

### Benefits
- Pure OpenWRT container (no Debian base)
- Smaller resource footprint
- Native OpenWRT environment
- Standard LXC template format
- Eliminates chroot complexity

### Implementation
```bash
var_os="openwrt"
var_version="23.05.5"
# Point to hosted template URL
```