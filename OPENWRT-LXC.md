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
```bash
# From checked out feature branch
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

## Architecture Notes
- **Base:** Debian 12 LXC container
- **OpenWRT:** Runs in chroot environment at `/opt/openwrt`
- **Management:** systemd service controls OpenWRT lifecycle
- **Network:** Default LAN 192.168.1.1/24, configurable via UCI