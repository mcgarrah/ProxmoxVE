# Proxmox VE Helper-Scripts - Project Structure

## Directory Organization

### `/ct/` - LXC Container Scripts
Main directory containing 400+ container creation scripts. Each script automates the deployment of a specific application.

**Structure:**
- `*.sh` - Container creation scripts (e.g., `homeassistant.sh`, `docker.sh`)
- `headers/` - ASCII art headers for each application (loaded by build system)

**Pattern:** Scripts follow naming convention `{app-name}.sh` and source the build system from `/misc/build.func`

### `/install/` - Post-Installation Scripts
Application-specific installation and configuration scripts executed inside containers after creation.

**Structure:**
- `*-install.sh` - Installation scripts matching container names (e.g., `homeassistant-install.sh`)

**Purpose:** Package installation, service configuration, initial setup, and application-specific customization

### `/misc/` - Core Framework
Shared functions and utilities that power the script ecosystem.

**Key Files:**
- `build.func` - Main build system with interactive prompts and container creation logic
- `install.func` - Common installation functions for Debian/Ubuntu containers
- `alpine-install.func` - Installation functions for Alpine-based containers
- `tools.func` - Utility functions for storage selection and system operations
- `core.func` - Core helper functions used across scripts
- `api.func` - API interaction functions
- `config-file.func` - Configuration file handling
- `create_lxc.sh` - Legacy LXC creation script
- `images/` - Logo and branding assets

### `/frontend/` - Web Interface
Next.js-based website (helper-scripts.com) for browsing and discovering scripts.

**Structure:**
- `src/app/` - Next.js app router pages
- `src/components/` - React components (UI, animations, layouts)
- `src/lib/` - Utility functions and helpers
- `src/hooks/` - Custom React hooks
- `src/styles/` - Global styles and Tailwind configuration
- `public/json/` - Script metadata and application data

**Tech Stack:** Next.js 15, React 19, TypeScript, Tailwind CSS, Radix UI

### `/api/` - Backend API
Go-based API server for script metadata and analytics.

**Structure:**
- `main.go` - API server implementation
- `go.mod` - Go module dependencies

**Tech Stack:** Go 1.23, Gorilla Mux, MongoDB driver, CORS support

### `/tools/` - Management Utilities
Scripts for Proxmox host management and container maintenance.

**Subdirectories:**
- `pve/` - Proxmox host tools (updates, backups, kernel management)
- `addon/` - Container add-ons (Tailscale, Netbird, monitoring)
- `copy-data/` - Data migration scripts between containers
- `headers/` - ASCII headers for tool scripts

### `/vm/` - Virtual Machine Scripts
Automated VM creation scripts for various operating systems.

**Structure:**
- `*-vm.sh` - VM creation scripts (e.g., `haos-vm.sh`, `openwrt-vm.sh`)
- `headers/` - ASCII headers for VM scripts

### `/.github/` - GitHub Configuration
Workflows, issue templates, and contributor documentation.

**Structure:**
- `workflows/` - CI/CD automation (testing, releases, frontend deployment)
- `CONTRIBUTOR_AND_GUIDES/` - Contributing guidelines and user guides
- `ISSUE_TEMPLATE/` - Bug reports and feature request templates
- `DISCUSSION_TEMPLATE/` - Discussion templates

### `/turnkey/` - TurnKey Linux Integration
Scripts for deploying TurnKey Linux appliances.

## Core Components and Relationships

### Script Execution Flow
1. User runs container script from `/ct/` (e.g., `bash homeassistant.sh`)
2. Script sources `/misc/build.func` for build system
3. Build system loads header from `/ct/headers/{app}`
4. Interactive prompts collect user preferences
5. Container created with `pct create` command
6. Post-install script from `/install/` executed inside container
7. Application configured and started

### Build System Architecture
- **Variables System**: Standardized variables (`var_cpu`, `var_ram`, `var_disk`, etc.)
- **Interactive Prompts**: Whiptail-based dialogs for configuration
- **Storage Selection**: Dynamic storage pool detection and selection
- **Network Configuration**: DHCP or static IP with gateway/VLAN support
- **Template Management**: Automatic template download and caching

### Header System
- External header files in `/ct/headers/` and `/tools/headers/`
- Loaded automatically by build system using `header_info` function
- ASCII art branding for each application
- Lowercase naming convention matching script names

### Function Libraries
- **build.func**: Container creation, prompts, settings management
- **install.func**: Debian/Ubuntu package management, service setup
- **alpine-install.func**: Alpine-specific package management
- **tools.func**: Storage operations, system utilities
- **core.func**: Messaging, error handling, color output

## Architectural Patterns

### Script Structure Pattern
```bash
#!/usr/bin/env bash
source <(curl -fsSL ${BASE_URL}/misc/build.func)
# Variable definitions
# Function definitions (if needed)
# Build system initialization
# Custom logic (if needed)
start  # Launch build system
```

### Container Types
- **Managed OS**: Standard Debian/Ubuntu/Alpine containers using build system
- **Unmanaged OS**: Custom containers requiring direct `pct create` (e.g., OpenWRT)
- **Privileged**: Full system access (CT_TYPE="0")
- **Unprivileged**: Restricted containers (CT_TYPE="1")

### Update Mechanism
Each script includes `update_script()` function for in-container updates, accessible via script re-execution inside the container.
