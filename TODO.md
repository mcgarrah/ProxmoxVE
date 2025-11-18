# ProxmoxVE Helper Scripts - TODO

## 🚧 Current Issues & Fixes Needed

### OpenWRT LXC Container Issues

#### Architecture Detection Warning

- **Issue**: Architecture detection failed: error in setup task (eval)
- **Status**: Falling back to amd64
- **Fix Needed**: Improve architecture detection in template creation
- **Workaround**: Use `pct set VMID --arch ARCH` to change manually

#### Container Naming Inconsistency

- **Issue**: Default LXC name in Proxmox shows as "openwrt" but should be "openwrt-lxc"
- **Current**: Hostname is "openwrt-lxc" but container name is "openwrt"
- **Fix Needed**: Update container creation to use consistent naming

#### Package Management & Updates

- **Missing**: Automatic package upgrade after first boot
- **Command**: `opkg update && opkg list-upgradable | cut -f 1 -d ' ' | xargs -r opkg upgrade`
- **Status**: Needs implementation in post-install script

#### System Upgrade Documentation

- **Missing**: Clear instructions for upgrading OpenWRT to latest version
- **Required Package**: `luci-app-attendedsysupgrade` for web-based upgrades
- **Alternative**: `auc` CLI upgrade tool
- **Status**: Needs documentation and automatic installation

## 📦 Package Installation Recommendations

### Essential Packages to Consider

```bash
opkg update && opkg install \
  luci \
  luci-app-attendedsysupgrade \
  luci-app-irqbalance \
  luci-app-sqm \
  luci-app-adblock-fast \
  luci-app-dockerman \
  luci-app-nlbwmon \
  luci-app-ksmbd \
  luci-app-hd-idle \
  kmod-fs-exfat \
  exfat-fsck \
  kmod-usb3 \
  kmod-usb-storage-uas \
  usbutils \
  block-mount \
  mount-utils \
  nano \
  htop \
  bmon \
  iperf3 \
  speedtestpp \
  luci-proto-wireguard \
  luci-app-upnp \
  ntfs-3g
```

### Security & SSL Packages

- `luci-app-acme` - SSL certificate management
- `acme-acmesh-dnsapi` - DNS API for certificate signing

### Network & VPN Packages

- `luci-app-ddns` - Dynamic DNS services
- `tailscale` (1.80.3-r1, 9.22 MiB) - Secure network between devices

### Administrative Packages

- `luci-mod-admin-full` (25.318.75869~531020c, ~994 B) - Full-featured admin control

## 🔧 Feature Enhancements

### Version Selection

- **Feature**: Add choice between OpenWRT version 23.x or 24.x rootfs at script start
- **Implementation**: Modify template creation script to support version selection
- **Status**: Planned enhancement

### DNS Integration

- **Feature**: OpenWRT has PowerDNS (pdns) as an option
- **Use Case**: Could be useful for Proxmox SDN DNS integration
- **Status**: Research needed and missing PowerDNS-Admin webui

## 🐛 Known Issues

### Template Creation

- **Issue**: Occasional hanging during template creation
- **Mitigation**: Added timeouts and better error handling
- **Status**: Monitoring for improvements

### Storage Limitations

- **Issue**: 255-character template path limit in Proxmox
- **Workaround**: Automatic template copying between storages
- **Status**: Handled in current implementation

### Network Configuration

- **Issue**: Previously had hardcoded network settings
- **Fix**: Now uses build system configuration properly
- **Status**: ✅ Resolved

## 📋 Development Tasks

### High Priority

1. Fix architecture detection warning
2. Implement automatic package upgrades
3. Add system upgrade documentation
4. Standardize container naming

### Medium Priority

1. Add version selection (23.x vs 24.x)
2. Implement recommended package installation options
3. Add PowerDNS integration research
4. Improve template creation reliability

### Low Priority

1. Enhanced package management UI
2. Custom package selection during installation
3. Integration with Proxmox SDN features

## 📚 Documentation Needs

### User Guides

- [ ] OpenWRT LXC setup and configuration guide
- [ ] System upgrade procedures
- [ ] Package management best practices
- [ ] Network configuration examples

### Technical Documentation

- [ ] Architecture detection troubleshooting
- [ ] Template creation process
- [ ] Container naming conventions
- [ ] Integration with Proxmox features

## 🔗 Useful Resources

- **ASCII Art Generator**: <https://patorjk.com/software/taag/#p=display&f=Slant&t=OpenWRT>
- **OpenWRT Documentation**: <https://openwrt.org/docs/start>
- **Proxmox LXC Documentation**: <https://pve.proxmox.com/wiki/Linux_Container>

## 📝 Notes

- All OpenWRT containers should use privileged mode for network management
- Template approach is preferred over Debian+chroot hybrid
- Native OpenWRT LXC provides better LuCI compatibility
- Build system handles network configuration automatically

---

*Last Updated: $(date)*
*Maintainer: Community Scripts Team*
