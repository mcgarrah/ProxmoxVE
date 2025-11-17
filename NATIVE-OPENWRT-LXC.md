# Native OpenWRT LXC Container Implementation

## Concept: Pure OpenWRT LXC Template

Instead of Debian 12 + OpenWRT chroot, use OpenWRT rootfs directly as LXC container base.

### Proxmox VE LXC OS Types
Proxmox supports various OS types for LXC containers:
- `debian`, `ubuntu`, `centos`, `fedora`, `alpine`
- **Custom OS types** possible via template system
- OpenWRT can be treated as custom Linux distribution

### Native OpenWRT Approach Benefits

#### Eliminates Chroot Issues
- ✅ **LuCI Compatibility**: Native environment, no runtime initialization issues
- ✅ **Package Management**: opkg works normally with network access
- ✅ **Service Management**: Native OpenWRT init system (procd)
- ✅ **Resource Efficiency**: No Debian base layer overhead

#### Technical Advantages
- **Smaller Footprint**: ~5MB vs ~500MB+ (Debian base)
- **Native Environment**: All OpenWRT tools work as expected
- **Standard LXC**: Uses Proxmox template system properly
- **Update Path**: Standard OpenWRT upgrade mechanisms

## Implementation Strategy

### Phase 1: Create OpenWRT LXC Template

```bash
# Download OpenWRT rootfs
OPENWRT_VERSION="24.10.4"
wget "https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/x86/64/openwrt-${OPENWRT_VERSION}-x86-64-rootfs.tar.gz"

# Extract and prepare for LXC
mkdir openwrt-lxc-template
tar -xzf openwrt-${OPENWRT_VERSION}-x86-64-rootfs.tar.gz -C openwrt-lxc-template

# LXC template modifications
cd openwrt-lxc-template

# Add LXC-specific configurations
echo "lxc" > etc/hostname
echo "127.0.0.1 localhost lxc" > etc/hosts

# Configure network for LXC
cat > etc/config/network << 'EOF'
config interface 'loopback'
    option ifname 'lo'
    option proto 'static'
    option ipaddr '127.0.0.1'
    option netmask '255.0.0.0'

config interface 'lan'
    option proto 'dhcp'
    option device 'eth0'
EOF

# Create LXC template
cd ..
tar -czf openwrt-${OPENWRT_VERSION}-lxc_amd64.tar.gz -C openwrt-lxc-template .
```

### Phase 2: Template Hosting

#### Option A: GitHub Releases
```bash
# Upload to ProxmoxVE repository releases
# URL: https://github.com/community-scripts/ProxmoxVE/releases/download/v1.0/openwrt-24.10.4-lxc_amd64.tar.gz
```

#### Option B: Proxmox Local Storage
```bash
# Copy to Proxmox template directory
cp openwrt-24.10.4-lxc_amd64.tar.gz /var/lib/vz/template/cache/
```

### Phase 3: Script Implementation

#### Modified Container Creation Script
```bash
#!/usr/bin/env bash
# ct/openwrt-native-lxc.sh

# Use OpenWRT as OS type
var_os="openwrt"
var_version="24.10.4"

# Template URL
TEMPLATE_URL="https://github.com/community-scripts/ProxmoxVE/releases/download/v1.0/openwrt-24.10.4-lxc_amd64.tar.gz"

# Container configuration
PCT_OPTIONS="
  -ostemplate ${TEMPLATE_URL}
  -hostname openwrt-native
  -cores 1
  -memory 256
  -rootfs local:8
  -net0 name=eth0,bridge=vmbr0,ip=dhcp
  -unprivileged 0
  -features nesting=1
"
```

#### Installation Script
```bash
#!/usr/bin/env bash
# install/openwrt-native-install.sh

# No installation needed - pure OpenWRT environment
# Just configure for LXC environment

msg_info "Configuring OpenWRT for LXC"

# Enable SSH access
uci set dropbear.@dropbear[0].PasswordAuth='on'
uci set dropbear.@dropbear[0].RootPasswordAuth='on'
uci commit dropbear

# Configure LuCI
uci set uhttpd.main.listen_http='0.0.0.0:80'
uci commit uhttpd

# Start services
/etc/init.d/dropbear start
/etc/init.d/uhttpd start

msg_ok "OpenWRT configured for LXC"
```

## Proxmox VE 7.4+ Native Support

### Research Findings
- Proxmox VE 7.4 introduced experimental OpenWRT LXC support
- Feature may be undocumented or in development
- Could leverage native LXC OS type detection

### Investigation Steps
1. **Check Proxmox Source**: Look for OpenWRT OS type in PVE codebase
2. **Test Native Creation**: Try creating LXC with `ostype=openwrt`
3. **Template Integration**: Use standard Proxmox template system

## Implementation Plan

### Immediate Actions
1. **Create Native Template**: Build OpenWRT LXC template
2. **Host Template**: Upload to accessible location
3. **Modify Scripts**: Update container creation for native approach
4. **Test LuCI**: Verify web interface works in native environment

### Expected Results
- ✅ **Full LuCI Functionality**: Native OpenWRT environment
- ✅ **Package Management**: opkg works normally
- ✅ **Smaller Footprint**: ~5MB vs ~500MB
- ✅ **Better Performance**: No chroot overhead
- ✅ **Standard Upgrades**: Native OpenWRT update path

## Comparison: Hybrid vs Native

| Aspect | Hybrid (Debian+chroot) | Native OpenWRT LXC |
|--------|------------------------|-------------------|
| **Size** | ~500MB+ | ~5MB |
| **LuCI** | ❌ Incompatible | ✅ Full support |
| **opkg** | ❌ Network issues | ✅ Works normally |
| **Updates** | Manual | ✅ Native OpenWRT |
| **Complexity** | High (chroot) | Low (standard LXC) |
| **Performance** | Good | ✅ Excellent |

## Next Steps
1. Build native OpenWRT LXC template
2. Test template creation and deployment
3. Verify LuCI functionality in native environment
4. Update ProxmoxVE scripts for native approach
5. Document native implementation benefits