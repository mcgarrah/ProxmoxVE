# OpenWRT LXC Critical Requirements

## HARD REQUIREMENTS - NEVER CHANGE

### OpenWRT Rootfs Method
- **CRITICAL**: OpenWRT LXC containers MUST use the rootfs method with unmanaged ostype
- **NEVER REVERT**: Do not change to Debian rootfs or managed ostype under any circumstances
- **Template Source**: Custom OpenWRT rootfs templates created via `misc/create-openwrt-template.sh`
- **Container Creation**: Direct `pct create` with `--ostype unmanaged` parameter

### Technical Implementation Details

#### Template Creation (`misc/create-openwrt-template.sh`)
- Downloads official OpenWRT rootfs archives from releases.openwrt.org
- Creates LXC-compatible templates in `/var/lib/vz/template/cache/`
- Template naming: `openwrt-{version}-lxc_amd64.tar.gz`
- Version detection: Automatically fetches latest 24.x series releases
- Validation: Size, integrity, and format verification with timeout handling

#### Container Provisioning (`ct/openwrt-lxc.sh`)
- **Privileged Container**: Always requires `--unprivileged 0` for networking capabilities
- **Unmanaged OS Type**: Uses `--ostype unmanaged` for native OpenWRT operation
- **Direct Creation**: Bypasses standard LXC creation for specialized OS handling
- **Network Configuration**: Native OpenWRT UCI system integration
- **Post-Install**: Automated setup via `install/openwrt-lxc-install.sh`

### Why These Requirements Exist

#### Native OpenWRT Operation
- OpenWRT requires its native init system and kernel modules
- Managed containers would interfere with OpenWRT's system management
- Rootfs method preserves OpenWRT's complete filesystem structure
- Unmanaged ostype allows OpenWRT to control its own services

#### Network Stack Requirements
- OpenWRT needs direct access to network interfaces
- Native UCI configuration system must remain intact
- Bridge and VLAN configuration requires privileged access
- Firewall and routing functionality depends on kernel capabilities

#### Template Integrity
- Official OpenWRT rootfs ensures compatibility and security
- Custom template creation maintains proper LXC integration
- Version tracking ensures latest security updates
- Validation prevents corrupted or incomplete installations

### Implementation Verification

#### Container Creation Command
```bash
pct create "$CTID" "$TEMPLATE_STORAGE:vztmpl/$var_template" \
  --hostname "$HN" \
  --memory "$RAM_SIZE" \
  --cores "$CORE_COUNT" \
  --rootfs "$CONTAINER_STORAGE:$DISK_SIZE" \
  --net0 "$NET_STRING" \
  --unprivileged 0 \
  --ostype unmanaged \
  --arch amd64 \
  --features "nesting=1" \
  --tags "$TAGS" \
  --onboot 1
```

#### Template Validation
- Template must exist in `/var/lib/vz/template/cache/`
- File size validation ensures complete download
- Integrity checks prevent corrupted installations
- Timeout handling prevents hanging operations

### Consequences of Deviation

#### Using Debian Rootfs
- Breaks OpenWRT's native init system
- Conflicts with UCI configuration management
- Prevents proper network stack operation
- Results in non-functional router/firewall

#### Using Managed OS Type
- Interferes with OpenWRT service management
- Breaks native package management (opkg)
- Prevents proper system updates
- Causes configuration conflicts

### Maintenance Guidelines

#### Template Updates
- Regularly check for new OpenWRT releases
- Update template creation script for new versions
- Maintain backward compatibility for existing containers
- Test template integrity before deployment

#### Container Management
- Preserve unmanaged ostype during updates
- Maintain privileged container status
- Keep UCI configuration system intact
- Ensure network capabilities remain functional

This approach ensures OpenWRT containers operate as intended, providing full router and firewall functionality within the Proxmox VE environment while maintaining the native OpenWRT experience.