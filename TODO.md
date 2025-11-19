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
- **Problem**: NSAPP variable was "openwrt" instead of "openwrt-lxc"
- **Fix**: Hardcoded hostname to "openwrt-lxc" in both default_settings and base settings
- **Status**: ✅ **RESOLVED** - Container now shows as "101 (openwrt-lxc)" in Proxmox console

#### Package Management & Updates

- **Missing**: Automatic package upgrade after first boot
- **Command**: `opkg update && opkg list-upgradable | cut -f 1 -d ' ' | xargs -r opkg upgrade`
- **Status**: ✅ **IMPLEMENTED** - Added to post-install script

#### System Upgrade Documentation

- **Missing**: Clear instructions for upgrading OpenWRT to latest version
- **Required Package**: `luci-app-attendedsysupgrade` for web-based upgrades
- **Alternative**: `auc` CLI upgrade tool (deprecated in v24+), `owut` is replacement for v24+
- **Status**: ✅ **IMPLEMENTED** - Added owut installation to post-install script
- **Note**: Untested in production, needs validation. Version-specific: auc for v23.x, owut for v24+

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

### Ideal Solution (Gist Script Integration)

#### Implementation Details from Gist Script Analysis

**Dual Interface Support**:
- Detect bridges: `ip link | grep -o 'vmbr[0-9]\+' | sort -u`
- Detect unbridged devices: Compare `ip link show` output with `bridge link show`
- Use whiptail radiolist for WAN/LAN interface selection
- Support both bridge and direct device assignment

**Network Configuration**:
```bash
# WAN (eth0) - DHCP
uci set network.wan=interface
uci set network.wan.proto='dhcp'
uci set network.wan.device='eth0'
# LAN (eth1) - Static
uci set network.lan=interface
uci set network.lan.proto='static'
uci set network.lan.ipaddr='$LAN_IP'
uci set network.lan.netmask='$LAN_NETMASK'
```

**Version Selection**:
- Detect latest: `curl -sSf "https://downloads.openwrt.org/releases/" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1`
- Stable URL: `https://downloads.openwrt.org/releases/$VER/targets/x86/64/openwrt-$VER-x86-64-rootfs.tar.gz`
- Snapshot URL: `https://downloads.openwrt.org/snapshots/targets/x86/64/openwrt-x86-64-rootfs.tar.gz`

**LuCI Installation for Snapshots**:
```bash
# Wait for network, then install
sleep 15
pct exec "$CTID" -- sh -c "opkg update; opkg install luci"
# Note: OpenWRT uses opkg package manager (not apk which is Alpine Linux)
```

**Password Configuration (Framework)**:
```bash
# Framework already provides comprehensive password management in advanced_settings()
# Features: validation, confirmation, automatic login option, space/length checks
# Available via: PW variable (formatted as "-password $password" or "" for autologin)
# Implementation: Use advanced_settings() or extract password prompts to custom function
```

**Template Age Check**:
```bash
# Refresh snapshots older than 1 day
FILE_AGE=$(($(date +%s) - $(stat -c %Y "$TEMPLATE_FILE")))
[ "$FILE_AGE" -gt 86400 ] && refresh_template
```

**HTTPS Configuration**:
```bash
# Generate self-signed certificate
openssl req -x509 -newkey rsa:2048 -keyout /etc/uhttpd.key -out /etc/uhttpd.crt -days 365 -nodes -subj "/CN=openwrt-lxc"
# Enable HTTPS and redirection
uci set uhttpd.main.cert='/etc/uhttpd.crt'
uci set uhttpd.main.key='/etc/uhttpd.key'
uci set uhttpd.main.redirect_https='1'
uci commit uhttpd
```

**Status**: High priority enhancement
**Note**: Must retain custom build_container() for unmanaged ostype support

### Version Selection (Legacy)

- **Feature**: Add choice between OpenWRT version 23.x or 24.x rootfs at script start
- **Implementation**: Modify template creation script to support version selection
- **Status**: Superseded by ideal solution above

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

### CTID Variable Not Set

- **Issue**: "Parameter verification failed. vmid: type check ('integer') failed - got ''"
- **Problem**: CTID variable not set early enough for build system description() function
- **Fix**: Set CTID="$CT_ID" at beginning of build_container() function
- **Status**: ✅ **RESOLVED**

## 📋 Development Tasks

### High Priority

1. ✅ ~~Fix architecture detection warning~~
2. ✅ ~~Implement automatic package upgrades~~
3. ✅ ~~Add system upgrade documentation~~
4. ✅ ~~Standardize container naming~~
5. **NEW**: Implement dual interface support (WAN/LAN) - use gist's bridge/device detection
6. **NEW**: Add OpenWRT version selection - integrate version detection from downloads.openwrt.org
7. **NEW**: Add optional LuCI installation for snapshots - use opkg package manager
8. **NEW**: Add version-conditional upgrade tool selection (auc for v23.x, owut for v24+)
8. **NEW**: Leverage framework password management - use existing advanced_settings() password prompts
9. **NEW**: Add HTTPS redirection and self-signed certificates for LuCI interface
10. **NEW**: Test and validate owut system upgrade functionality
11. **NEW**: Add comprehensive package selection during installation
12. **NEW**: Enable TUN support for VPN functionality (framework already supports)
13. **NEW**: Leverage SSH key management for secure OpenWRT access
14. **NEW**: Extend bridge selection for dual WAN/LAN configuration
15. **NEW**: Use config file system for OpenWRT deployment templates
16. **EVAL**: Test framework TUN support with OpenWRT kernel modules
17. **EVAL**: Evaluate Dropbear SSH vs OpenSSH framework integration
18. **EVAL**: Test UCI network configuration vs framework network settings
19. **EVAL**: Assess OpenWRT password management vs framework authentication
20. **EVAL**: Validate FUSE support with OpenWRT filesystem modules
21. ✅ ~~Fix missing interactive prompts~~
22. ✅ ~~Fix incorrect IP address display~~

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

## 🏗️ Framework Features Available in advanced_settings()

### Network Configuration (Needs OpenWRT Evaluation)
- **Bridge Detection**: ✅ Compatible - Proxmox bridge detection works regardless of guest OS
- **IPv4 Methods**: ⚠️ **EVALUATE** - OpenWRT uses UCI network config, not standard Linux networking
- **IPv6 Support**: ⚠️ **EVALUATE** - OpenWRT IPv6 configuration differs from Debian/Ubuntu
- **Gateway Configuration**: ⚠️ **EVALUATE** - OpenWRT uses UCI for routing configuration
- **DNS Configuration**: ⚠️ **EVALUATE** - OpenWRT uses dnsmasq, not systemd-resolved
- **VLAN Support**: ✅ Compatible - VLAN tagging handled at LXC level
- **MAC Address**: ✅ Compatible - Hardware level configuration
- **MTU Configuration**: ✅ Compatible - Network interface level setting

### Container Configuration
- **Container Type**: Privileged/Unprivileged selection (OpenWRT needs privileged)
- **Resource Allocation**: CPU cores, RAM, disk size with validation
- **Container ID**: Auto-detection of next available ID with validation
- **Hostname**: RFC 1123 compliant hostname validation
- **Tags**: Custom tagging system for organization

### Security & Access (Mixed Compatibility)
- **Root Password**: ⚠️ **EVALUATE** - OpenWRT uses different password system (no /etc/shadow by default)
- **SSH Configuration**: ⚠️ **EVALUATE** - OpenWRT uses Dropbear SSH, not OpenSSH
- **SSH Keys**: ⚠️ **EVALUATE** - Dropbear SSH key format/location may differ
- **FUSE Support**: ⚠️ **EVALUATE** - OpenWRT kernel modules and filesystem support differs
- **TUN Support**: ⚠️ **EVALUATE** - OpenWRT networking stack may handle TUN devices differently

### Integration Features (Mixed Compatibility)
- **APT Cacher**: ❌ **INCOMPATIBLE** - OpenWRT uses opkg package manager, not APT
- **Config File**: ✅ Compatible - LXC configuration works regardless of guest OS
- **Verbose Mode**: ✅ Compatible - Logging handled at framework level
- **Diagnostics**: ✅ Compatible - Telemetry collection independent of guest OS

### OpenWRT Compatibility Assessment

**✅ Fully Compatible Features**:
```bash
# Container configuration (LXC level)
CT_TYPE="0"          # Privileged container support
BRIDGE_DETECTION     # Network bridge detection
VLAN_SUPPORT         # VLAN tagging
MAC_ADDRESS          # Hardware address assignment
MTU_CONFIG           # Interface MTU settings
CONFIG_FILE_SYSTEM   # Deployment templates
VERBOSE_MODE         # Framework logging
DIAGNOSTICS          # Telemetry collection
```

**⚠️ Requires Evaluation/Adaptation**:
```bash
# OpenWRT-specific implementations needed
PASSWORD_MGMT        # Dropbear vs OpenSSH differences
SSH_KEY_MGMT         # Dropbear key format/location
NETWORK_CONFIG       # UCI vs standard Linux networking
IPV6_CONFIG          # OpenWRT IPv6 vs systemd-networkd
DNS_CONFIG           # dnsmasq vs systemd-resolved
TUN_SUPPORT          # OpenWRT kernel modules
FUSE_SUPPORT         # OpenWRT filesystem support
```

**❌ Incompatible Features**:
```bash
APT_CACHER           # OpenWRT uses opkg, not APT
                     # Note: OpenWRT has always used opkg (v23, v24, snapshots)
                     # Never use "apk" (Alpine Linux package manager)
```

**Framework Integration Strategy**:
1. **✅ Use existing bridge detection** - Works at Proxmox level
2. **⚠️ Evaluate TUN support** - Test OpenWRT kernel module compatibility
3. **⚠️ Adapt SSH key management** - Account for Dropbear differences
4. **✅ Extend bridge selection** - For dual WAN/LAN interfaces
5. **✅ Use config file system** - For OpenWRT deployment templates
6. **⚠️ Custom network configuration** - Implement UCI-based setup
7. **⚠️ Custom password management** - Handle OpenWRT authentication

**Evaluation Priority**:
1. **High**: Network configuration (UCI vs standard Linux)
2. **High**: SSH/Password management (Dropbear vs OpenSSH)
3. **Medium**: TUN/FUSE support (kernel module compatibility)
4. **Low**: IPv6 configuration (can use basic setup initially)

## 🛠️ Implementation Patterns from Gist Script

### Key Functions to Adapt

**Network Detection**:
```bash
detect_network_options() {
    BRIDGE_LIST=($(ip link | grep -o 'vmbr[0-9]\+' | sort -u))
    # Detect unbridged devices by comparing all devices with bridged ones
}
```

**Whiptail Helper**:
```bash
whiptail_radiolist() {
    local title="$1" prompt="$2" height="$3" width="$4" items=("${@:5}")
    whiptail --title "$title" --radiolist "$prompt" "$height" "$width" "$((${#items[@]} / 3))" "${items[@]}" 3>&1 1>&2 2>&3
}
```

**Version Detection**:
```bash
detect_latest_version() {
    curl -sSf "https://downloads.openwrt.org/releases/" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -1
}
```

**Template Age Management**:
```bash
# Check if snapshot is older than 1 day and refresh if needed
FILE_AGE=$(($(date +%s) - $(stat -c %Y "$TEMPLATE_FILE")))
[ "$FILE_AGE" -gt 86400 ] && refresh_snapshot
```

### Integration Strategy

1. **Preserve Framework Integration**: Keep using build.func patterns where possible
2. **Add Custom Prompts**: Insert gist-style prompts before calling build_container()
3. **Enhance build_container()**: Add dual interface and UCI configuration logic
4. **Template Management**: Integrate version selection with existing template creation

## 📝 Notes

- All OpenWRT containers should use privileged mode for network management
- Template approach is preferred over Debian+chroot hybrid
- Native OpenWRT LXC provides better LuCI compatibility
- Build system handles network configuration automatically
- Custom build_container() required for unmanaged ostype support
- Gist script patterns can enhance user experience while maintaining framework consistency

---

*Last Updated: $(date)*
*Maintainer: Community Scripts Team*

## 🔄 OpenWRT Version Compatibility (v23 vs v24)

### Major Differences Between Versions

#### Package Management & Repositories
- **v23.05.x**: Stable package feeds, frozen package versions
- **v24.10.x**: Updated package feeds, newer software versions
- **Snapshots**: Rolling release, latest packages but potentially unstable
- **Impact**: Package availability may differ between versions

#### Kernel & System Changes
- **v23**: Linux kernel 5.15.x series
- **v24**: Linux kernel 6.6.x series  
- **Impact**: Different kernel module availability, hardware support changes

#### LuCI Interface Updates
- **v23**: LuCI 23.x branch with older theme/layout
- **v24**: LuCI 24.x branch with updated interface, new features
- **Impact**: Different web interface appearance and functionality

#### Network Configuration
- **v23**: Traditional network configuration structure
- **v24**: Enhanced network configuration with new options
- **Impact**: UCI network commands may have different available options

#### Security & SSL
- **v23**: OpenSSL 1.1.x or mbedTLS
- **v24**: OpenSSL 3.x or updated mbedTLS
- **Impact**: Certificate handling and SSL/TLS behavior differences

#### Upgrade Tools (Already Documented)
- **v23**: `auc` (Attended sysUpgrade Client)
- **v24**: `owut` (OpenWrt Upgrade Tool) - replacement for auc

### Implementation Considerations

#### Version Detection Strategy
```bash
# Detect OpenWRT version for conditional logic
detect_openwrt_version() {
    local version_file="/etc/openwrt_release"
    if [ -f "$version_file" ]; then
        OPENWRT_VERSION=$(grep 'DISTRIB_RELEASE' "$version_file" | cut -d"'" -f2)
        OPENWRT_MAJOR=$(echo "$OPENWRT_VERSION" | cut -d. -f1)
        OPENWRT_MINOR=$(echo "$OPENWRT_VERSION" | cut -d. -f2)
    else
        # Fallback for template creation (before container exists)
        OPENWRT_VERSION="unknown"
        OPENWRT_MAJOR="24"  # Default to v24 for new installations
    fi
}
```

#### Package Installation Compatibility
```bash
# Version-specific package installation
install_version_packages() {
    if [ "$OPENWRT_MAJOR" -ge 24 ]; then
        # v24+ specific packages
        opkg install owut luci-app-attendedsysupgrade
        # New v24 packages that may not exist in v23
        opkg install luci-app-advanced-reboot || echo "Advanced reboot not available"
    else
        # v23.x specific packages  
        opkg install auc luci-app-attendedsysupgrade
        # Note: luci-app-advanced-reboot is v24+ only, no v23 equivalent
    fi
}
```

#### Template URL Structure
```bash
# Version-specific download URLs
get_template_url() {
    local version="$1"
    local arch="x86/64"
    
    if [ "$version" = "snapshot" ]; then
        echo "https://downloads.openwrt.org/snapshots/targets/$arch/openwrt-$arch-rootfs.tar.gz"
    else
        echo "https://downloads.openwrt.org/releases/$version/targets/$arch/openwrt-$version-$arch-rootfs.tar.gz"
    fi
}
```

### Potential Issues & Mitigations

#### 1. Package Availability Differences
- **Issue**: Some packages exist in v24 but not v23, or vice versa
- **Mitigation**: Use conditional installation with fallbacks
- **Example**: `luci-app-advanced-reboot` (v24+ only), some packages have no v23 equivalent

#### 2. UCI Configuration Changes
- **Issue**: Network/system configuration options may differ
- **Mitigation**: Version-specific UCI commands where needed
- **Example**: Firewall rules syntax may have minor differences

#### 3. Kernel Module Compatibility
- **Issue**: Hardware drivers and kernel modules differ between kernel versions
- **Mitigation**: Document known compatibility issues, provide version-specific recommendations

#### 4. SSL/TLS Certificate Handling
- **Issue**: OpenSSL 3.x in v24 has stricter certificate validation
- **Mitigation**: Update certificate generation for v24 compatibility

#### 5. Theme and Interface Changes
- **Issue**: LuCI themes and layouts differ between versions
- **Mitigation**: Document interface differences, provide version-specific screenshots

### Version Selection Implementation Plan

#### User Interface
```bash
# Version selection prompt
select_openwrt_version() {
    local versions=(
        "24.10.4" "Latest Stable (Recommended)" "ON"
        "23.05.5" "Previous Stable (LTS)" "OFF"  
        "snapshot" "Development (Latest Features)" "OFF"
    )
    
    SELECTED_VERSION=$(whiptail --title "OpenWRT Version" \
        --radiolist "Choose OpenWRT version:" 16 70 3 \
        "${versions[@]}" 3>&1 1>&2 2>&3)
}
```

#### Template Management
```bash
# Version-specific template creation
create_version_template() {
    local version="$1"
    local template_name="openwrt-${version}-lxc_amd64.tar.gz"
    
    # Check if template exists and is recent (for snapshots)
    if [ "$version" = "snapshot" ]; then
        check_snapshot_age "$template_name"
    fi
    
    # Create template with version-specific URL
    download_and_create_template "$version" "$template_name"
}
```

### Testing Requirements

#### Version-Specific Testing Matrix
- **v23.05.x**: Test package installation, upgrade tools (auc), LuCI functionality
- **v24.10.x**: Test package installation, upgrade tools (owut), new LuCI features  
- **Snapshots**: Test latest packages, bleeding-edge features, stability
- **Cross-version**: Test upgrade paths from v23 to v24

#### Compatibility Validation
- Network configuration consistency across versions
- Package installation success rates
- LuCI interface functionality
- System upgrade procedures
- Container resource usage differences

### Documentation Updates Needed

#### User-Facing Documentation
- Version comparison table (features, stability, use cases)
- Upgrade procedures between versions
- Version-specific troubleshooting guides
- Package availability matrices

#### Technical Documentation  
- Version detection implementation
- Conditional package installation logic
- Template management for multiple versions
- Testing procedures for version compatibility

### Development Tasks (Version-Specific)

#### High Priority
1. **Implement version selection UI** - Add whiptail-based version chooser
2. **Version-conditional package installation** - Handle auc/owut and other differences
3. **Template management updates** - Support multiple version templates
4. **Version detection in post-install** - Reliable version identification

#### Medium Priority  
1. **Package compatibility matrix** - Document package differences between versions
2. **UCI configuration validation** - Test network/system config across versions
3. **Upgrade path testing** - Validate v23 to v24 upgrade procedures
4. **Performance comparison** - Document resource usage differences

#### Low Priority
1. **Theme customization** - Handle LuCI interface differences
2. **Advanced feature toggles** - Version-specific feature availability
3. **Kernel module documentation** - Hardware compatibility matrices
4. **SSL/TLS optimization** - Version-specific certificate handling

### Notes
- Default to v24.10.x for new installations (latest stable)
- Maintain v23.05.x support for users requiring LTS stability
- Snapshot support for advanced users and testing
- Version selection should be prominent in installation flow
- Consider automatic version detection for existing containers during updates
