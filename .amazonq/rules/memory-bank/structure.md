# Project Structure

## Directory Organization

### Core Installation Scripts
```
ct/                          # LXC Container scripts (400+ applications)
├── headers/                 # Script metadata and configuration headers
├── *.sh                    # Individual application installation scripts
install/                     # Installation scripts for applications
├── *-install.sh            # Detailed installation procedures
vm/                          # Virtual Machine deployment scripts
├── headers/                 # VM configuration headers
├── *.sh                    # VM creation and setup scripts
```

### Infrastructure & Utilities
```
misc/                        # Core functionality and utilities
├── images/                  # Project logos and visual assets
├── *.func                  # Shared function libraries
├── create_lxc.sh           # LXC container creation logic
├── create-openwrt-template.sh # OpenWrt template generation
tools/                       # System management and maintenance tools
├── addon/                   # Additional utility scripts
├── copy-data/              # Data migration utilities
├── pve/                    # Proxmox VE specific tools
```

### Web Interface & API
```
frontend/                    # Next.js web application
├── src/
│   ├── app/                # Next.js app router pages
│   ├── components/         # React components
│   ├── config/            # Application configuration
│   ├── hooks/             # Custom React hooks
│   ├── lib/               # Utility libraries
│   └── styles/            # CSS and styling
├── public/                # Static assets and JSON data
│   └── json/              # Script metadata for website
api/                        # Go-based API server
├── main.go                # API server implementation
├── go.mod                 # Go module dependencies
```

### Documentation & Governance
```
.github/                     # GitHub configuration and workflows
├── CONTRIBUTOR_AND_GUIDES/ # Contribution guidelines and documentation
├── ISSUE_TEMPLATE/        # Issue reporting templates
├── workflows/             # CI/CD automation workflows
├── CODE_OF_CONDUCT.md     # Community guidelines
├── FUNDING.yml            # Sponsorship information
```

### Configuration & Metadata
```
turnkey/                     # TurnKey Linux integration
.amazonq/rules/memory-bank/ # AI assistant knowledge base
CHANGELOG.md                # Version history and updates
SECURITY.md                 # Security policies and supported versions
```

## Core Components

### Script Architecture

#### Core Provisioning Infrastructure
- **`misc/create_lxc.sh`**: Central LXC container creation engine with interactive prompts, storage selection, and network configuration
- **`misc/create-openwrt-template.sh`**: Specialized OpenWRT template generation for both VM and LXC deployments
- **Shared Function Libraries (`misc/*.func`)**: Core utilities for container lifecycle, network setup, and resource management

#### LXC Container Scripts (`ct/`)
- **Purpose**: Deploy applications in lightweight Linux containers
- **Structure**: Each script follows standardized installation patterns using shared function libraries
- **Key Infrastructure Scripts**:
  - `ct/openwrt-lxc.sh`: OpenWRT router/firewall in LXC (privileged container required)
  - `ct/docker.sh`: Docker containerization platform
  - `ct/home-assistant.sh`: Home automation hub
- **Features**: Automated dependency resolution, service configuration, security hardening
- **Template System**: Uses `/var/lib/vz/template/cache/` for container templates

#### Virtual Machine Scripts (`vm/`)
- **Purpose**: Deploy complete operating systems and specialized environments
- **Key VM Scripts**:
  - `vm/openwrt-vm.sh`: OpenWRT router/firewall as full VM
  - `vm/haos-vm.sh`: Home Assistant Operating System
  - `vm/opnsense-vm.sh`: OPNsense firewall distribution
  - `vm/debian-vm.sh`, `vm/ubuntu2404-vm.sh`: Linux distribution VMs
- **Features**: Automated VM creation, disk allocation, network configuration, ISO handling
- **Architecture Support**: AMD64 primary, ARM64 for select applications

#### Installation Scripts (`install/`)
- **Purpose**: Detailed application-specific installation procedures
- **Integration**: Called by container scripts for complex deployments
- **Key Scripts**: `install/openwrt-lxc-install.sh` for OpenWRT post-container setup
- **Customization**: Environment-specific configurations and optimizations

### Shared Libraries (`misc/*.func`)

#### Core Functions (`core.func`)
- Container lifecycle management
- Network configuration and validation
- Resource allocation and optimization
- Error handling and logging

#### Build Functions (`build.func`)
- Template management and caching
- Package installation and updates
- Service configuration and startup

#### Installation Functions (`install.func`)
- Application-specific installation logic
- Dependency resolution and management
- Configuration file generation

#### API Functions (`api.func`)
- Web interface integration
- Script metadata management
- Usage analytics and reporting

### Management Tools (`tools/`)

#### System Maintenance (`tools/pve/`)
- **clean-lxcs.sh**: Container cleanup and optimization
- **update-lxcs.sh**: Bulk container updates
- **host-backup.sh**: System backup automation
- **kernel-clean.sh**: Kernel maintenance and cleanup

#### Add-on Utilities (`tools/addon/`)
- **netdata.sh**: System monitoring installation
- **tailscale-lxc.sh**: VPN integration for containers
- **filebrowser.sh**: Web-based file management

#### Data Migration (`tools/copy-data/`)
- Application data transfer between containers
- Configuration backup and restore
- Version migration utilities

## Architectural Patterns

### Container Provisioning Workflow
- **Template Management**: Automated download and caching of container templates in `/var/lib/vz/template/cache/`
- **Storage Selection**: Interactive storage pool selection for templates and container data using `pvesm` commands
- **Network Configuration**: Automated bridge setup, VLAN support, and IP assignment (DHCP/static)
- **Resource Allocation**: Dynamic CPU, memory, and disk allocation based on application requirements
- **Privilege Management**: Automatic privileged/unprivileged container selection (OpenWRT requires privileged)
- **Container Creation**: Direct `pct create` commands with proper parameter handling for unmanaged OS types

### OpenWRT Development Focus
- **HARD REQUIREMENT**: OpenWRT-LXC MUST use rootfs method with unmanaged ostype - NEVER revert to Debian rootfs or managed ostype
- **Dual Deployment**: Both LXC container (`ct/openwrt-lxc.sh`) and VM (`vm/openwrt-vm.sh`) implementations
- **Template Generation**: Custom OpenWRT rootfs creation via `misc/create-openwrt-template.sh`
- **Network Integration**: Native OpenWRT networking stack within Proxmox VE infrastructure
- **Version Management**: Automated detection of latest OpenWRT releases (24.x series) from official sources
- **Post-Install Configuration**: Automated UCI configuration and service setup via `install/openwrt-lxc-install.sh`
- **Privileged Requirements**: OpenWRT native requires privileged containers for full networking capabilities
- **Template Validation**: Comprehensive template creation verification with timeout and error handling

### Modular Design
- **Separation of Concerns**: Each script handles a specific application or function
- **Reusable Components**: Shared functions in `misc/*.func` reduce code duplication
- **Standardized Interfaces**: Consistent parameter handling and output formatting across all scripts
- **Build System Integration**: Common `build.func` and `core.func` libraries for container lifecycle

### Configuration Management
- **Header Files**: Centralized metadata for each script in `ct/headers/` and `vm/headers/`
- **Environment Variables**: Flexible configuration without code changes
- **Template System**: Standardized configuration file generation
- **UCI Integration**: OpenWRT Unified Configuration Interface support for network configuration

### Error Handling & Logging
- **Graceful Degradation**: Scripts continue operation despite non-critical failures
- **Comprehensive Logging**: Detailed installation and error logs with `msg_info`, `msg_ok`, `msg_error` functions
- **User Feedback**: Clear progress indicators and error messages
- **Timeout Management**: Network operations with configurable timeouts (300s for template creation)
- **Retry Logic**: IP detection with multiple attempts and fallback handling

### Security Framework
- **Privilege Separation**: Minimal required permissions for each operation
- **Container Security**: Automatic privileged/unprivileged determination based on application needs
- **Input Validation**: Sanitization of user inputs and parameters
- **Secure Defaults**: Conservative security configurations out-of-the-box
- **Network Isolation**: VLAN and bridge configuration for network segmentation
- **Template Verification**: Size and integrity checks for downloaded templates

### Update Mechanism
- **Version Tracking**: Automated detection of application updates via GitHub API and release feeds
- **Rollback Capability**: Safe update procedures with fallback options
- **Dependency Management**: Coordinated updates across related components
- **Template Updates**: Automatic template refresh for base OS updates
- **Package Management**: Integration with `opkg` for OpenWRT package updates

## Integration Points

### Proxmox VE Integration
- **API Utilization**: Direct integration with Proxmox VE management APIs
- **Resource Management**: Intelligent allocation of CPU, memory, and storage
- **Network Configuration**: Automated VLAN and bridge setup

### Container Orchestration
- **LXC Management**: Advanced container lifecycle operations
- **Resource Monitoring**: Real-time performance tracking
- **Service Discovery**: Automated service registration and networking

### Web Interface Integration
- **Script Catalog**: Searchable database of available applications
- **Installation Wizard**: Guided setup process for complex deployments
- **Status Dashboard**: Real-time monitoring of deployed services

This structure enables the project to maintain scalability while providing a consistent user experience across hundreds of different applications and use cases.