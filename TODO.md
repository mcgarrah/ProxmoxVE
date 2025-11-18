# ProxmoxVE Helper Scripts - TODO

## 🚧 Current Issues & Fixes Needed

### OpenWRT LXC Container Issues

#### Architecture Detection Warning

- **Issue**: Architecture detection failed: error in setup task (eval)
- **Status**: ✅ **RESOLVED** - Falls back to amd64 successfully
- **Fix**: Template creation works with fallback mechanism
- **Note**: Not critical as amd64 is correct for most deployments

#### Container Naming Inconsistency

- **Issue**: Default LXC name in Proxmox shows as "openwrt" but should be "openwrt-lxc"
- **Current**: Hostname is "openwrt-lxc" but container name is "openwrt"
- **Status**: ✅ **RESOLVED** - Build system handles naming correctly
- **Note**: Container name follows Proxmox conventions, hostname is customizable

#### Package Management & Updates

- **Missing**: Automatic package upgrade after first boot
- **Command**: `opkg update && opkg list-upgradable | cut -f 1 -d ' ' | xargs -r opkg upgrade`
- **Status**: ✅ **IMPLEMENTED** - Added to post-install script

#### System Upgrade Documentation

- **Missing**: Clear instructions for upgrading OpenWRT to latest version
- **Required Package**: `luci-app-attendedsysupgrade` for web-based upgrades
- **Alternative**: `auc` CLI upgrade tool (deprecated), `owut` is replacement
- **Status**: ✅ **IMPLEMENTED** - Added owut installation to post-install script
- **Note**: Untested in production, needs validation

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
- **Status**: ✅ **RESOLVED**

### Shell Compatibility Issues

- **Issue**: Post-install script used bash syntax in OpenWRT ash environment
- **Problem**: Function corruption "build_openwrt_containereation" and variable contamination
- **Fix**: Converted to ash-compatible syntax, fixed function names, redirected debug to stderr
- **Status**: ✅ **RESOLVED**

### Header System Standardization

- **Issue**: Inline header_info() functions and incorrect ASCII art
- **Problem**: "OpenLT" instead of "OpenWRT" in ASCII art
- **Fix**: Moved to external header files, corrected ASCII art, added subtitle
- **Status**: ✅ **RESOLVED**

### Interactive Prompts Missing

- **Issue**: Script bypasses interactive prompts for CTID, network settings, etc.
- **Problem**: Custom build_openwrt_container() function instead of standard build system
- **Fix**: Use standard start() and build_container() functions from build.func
- **Status**: ✅ **RESOLVED**

### Incorrect IP Address Display

- **Issue**: Script shows hardcoded 192.168.1.1 instead of actual container IP
- **Problem**: IP detection happens before container gets DHCP address
- **Fix**: Move IP detection after container is fully started and configured
- **Status**: ✅ **RESOLVED**

## 📋 Development Tasks

### High Priority

1. ✅ ~~Fix architecture detection warning~~
2. ✅ ~~Implement automatic package upgrades~~
3. ✅ ~~Add system upgrade documentation~~
4. ✅ ~~Standardize container naming~~
5. **NEW**: Test and validate owut system upgrade functionality
6. **NEW**: Add comprehensive package selection during installation
7. ✅ ~~Fix missing interactive prompts~~
8. ✅ ~~Fix incorrect IP address display~~

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

- [x] Architecture detection troubleshooting
- [x] Template creation process
- [x] Container naming conventions
- [x] Shell compatibility issues (ash vs bash)
- [x] Header system standardization
- [ ] Integration with Proxmox features
- [ ] Post-install script troubleshooting guide

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
