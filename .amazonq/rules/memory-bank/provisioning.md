# VM and LXC Provisioning Architecture

## Core Provisioning Scripts

### LXC Container Creation (`misc/create_lxc.sh`)
- **Interactive Build System**: Comprehensive user prompts for container configuration
- **Storage Pool Selection**: Dynamic detection and selection of available Proxmox storage
- **Network Configuration**: Bridge, VLAN, IP assignment with validation
- **Template Management**: Automated template download and caching
- **Resource Allocation**: CPU, memory, disk sizing with intelligent defaults
- **Security Context**: Automatic privileged/unprivileged container determination

### OpenWRT Specialized Provisioning

#### Template Creation (`misc/create-openwrt-template.sh`)
- **Rootfs Generation**: Creates custom OpenWRT LXC templates from official releases
- **Version Detection**: Automatically fetches latest OpenWRT 24.x series releases
- **Architecture Support**: AMD64 template generation for Proxmox VE compatibility
- **Template Validation**: Size, integrity, and format verification

#### OpenWRT LXC Container (`ct/openwrt-lxc.sh`)
- **CRITICAL REQUIREMENT**: Uses OpenWRT rootfs method with unmanaged ostype - NEVER revert to Debian rootfs or managed ostype
- **Privileged Container**: Required for full OpenWRT networking capabilities
- **Custom Build Process**: Bypasses standard LXC creation for unmanaged OS type
- **Network Integration**: Native OpenWRT networking within Proxmox infrastructure
- **Post-Install Configuration**: Automated UCI setup and service initialization
- **IP Detection**: Retry logic for network configuration with fallback handling

#### OpenWRT VM Deployment (`vm/openwrt-vm.sh`)
- **ISO Management**: Automated OpenWRT x86_64 ISO download and verification
- **VM Creation**: Direct QEMU/KVM integration with optimal settings
- **Network Bridging**: Automatic bridge configuration for router functionality
- **Resource Optimization**: Minimal resource allocation for embedded router use

## Container Lifecycle Management

### Creation Workflow
1. **Parameter Validation**: User input sanitization and requirement checking
2. **Storage Selection**: Interactive storage pool selection with capacity display
3. **Template Preparation**: Download, cache, and verify container templates
4. **Network Setup**: Bridge configuration, IP assignment, VLAN setup
5. **Container Creation**: Direct `pct create` with application-specific parameters
6. **Post-Install**: Application-specific configuration and service startup
7. **Verification**: Health checks and connectivity validation

### Privilege Management
- **Automatic Detection**: Application requirements determine container privilege level
- **OpenWRT Exception**: Always requires privileged containers for networking
- **Security Isolation**: Unprivileged containers for standard applications
- **Feature Flags**: Nesting, FUSE, and other capabilities based on needs

### Network Configuration Patterns
- **Bridge Selection**: Automatic vmbr0 default with override capability
- **IP Assignment**: DHCP default with static IP support
- **VLAN Support**: Tagged VLAN configuration for network segmentation
- **MAC Address**: Custom MAC assignment for specific networking needs
- **MTU Configuration**: Jumbo frame support for high-performance applications

## VM Provisioning Architecture

### VM Creation Workflow
1. **ISO Management**: Automated download and verification of OS images
2. **Storage Allocation**: Disk size calculation and storage pool selection
3. **Hardware Configuration**: CPU, memory, and device assignment
4. **Network Setup**: Bridge attachment and network device configuration
5. **Boot Configuration**: UEFI/BIOS selection and boot order setup
6. **VM Creation**: QEMU configuration generation and VM instantiation

### Specialized VM Types
- **Router VMs**: OpenWRT, OPNsense with multiple network interfaces
- **OS VMs**: Debian, Ubuntu with cloud-init support
- **Appliance VMs**: Home Assistant OS, specialized distributions
- **Development VMs**: Docker, Kubernetes development environments

## Template and Image Management

### Container Templates
- **Storage Location**: `/var/lib/vz/template/cache/` for local storage
- **Multi-Storage Support**: Template distribution across storage pools
- **Version Tracking**: Automated detection of template updates
- **Integrity Verification**: Checksum validation for downloaded templates

### VM Images
- **ISO Repository**: Automated download from official sources
- **Cloud Images**: Cloud-init enabled images for rapid deployment
- **Custom Images**: Support for user-provided ISO files
- **Storage Optimization**: Thin provisioning and compression support

## Error Handling and Recovery

### Robust Error Management
- **Timeout Handling**: Network operations with configurable timeouts
- **Retry Logic**: Multiple attempts for network-dependent operations
- **Graceful Degradation**: Fallback options for failed operations
- **Cleanup Procedures**: Automatic cleanup of failed deployments

### Validation and Verification
- **Pre-flight Checks**: System requirements and dependency validation
- **Post-deployment Verification**: Service health checks and connectivity tests
- **Resource Monitoring**: CPU, memory, and disk usage validation
- **Network Connectivity**: IP assignment and routing verification

## Integration with Proxmox VE

### API Integration
- **PVE API**: Direct integration with Proxmox VE management APIs
- **Storage Management**: `pvesm` commands for storage operations
- **Container Management**: `pct` commands for LXC operations
- **VM Management**: `qm` commands for QEMU operations

### Resource Management
- **Dynamic Allocation**: Intelligent resource sizing based on application needs
- **Storage Pools**: Multi-storage support with capacity monitoring
- **Network Resources**: Bridge and VLAN management
- **Hardware Passthrough**: USB, GPU, and other device passthrough support

This provisioning architecture enables the deployment of hundreds of applications while maintaining consistency, security, and reliability across the entire Proxmox VE infrastructure.