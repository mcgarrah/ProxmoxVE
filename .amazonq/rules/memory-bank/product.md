# Proxmox VE Helper-Scripts - Product Overview

## Purpose
Community-driven automation scripts for Proxmox VE that simplify the deployment and management of LXC containers and virtual machines. Originally created by tteck, now maintained by the community as a legacy project.

## Value Proposition
- **One-Command Installations**: Deploy 400+ applications and services with a single bash command
- **Interactive Configuration**: Simple mode for beginners, advanced options for power users
- **Zero Manual Setup**: Automated container/VM creation, networking, and post-installation configuration
- **Community Maintained**: Active development with contributions from users worldwide
- **Production Ready**: Battle-tested scripts used by thousands of Proxmox users

## Key Features

### Script Categories
- **LXC Containers** (400+ scripts): Pre-configured containers for popular self-hosted applications
- **Virtual Machines**: Automated VM creation for operating systems and specialized platforms
- **Management Tools**: Utilities for backup, updates, monitoring, and system maintenance
- **Add-ons**: Extensions for existing containers (Tailscale, Netbird, monitoring tools)

### Core Capabilities
- Automated template creation and caching
- Interactive prompts with sensible defaults
- DHCP or static IP configuration
- Storage pool selection
- Resource allocation (CPU, RAM, disk)
- Privileged/unprivileged container support
- Hardware acceleration support
- Built-in update mechanisms
- Post-installation configuration scripts

### User Experience
- **Web Interface**: Browse and copy commands from helper-scripts.com
- **PVEScripts-Local**: In-Proxmox UI menu for script management
- **CLI Execution**: Direct bash execution from Proxmox shell
- **Flexible Modes**: Default settings or advanced customization

## Target Users

### Primary Audience
- Proxmox VE administrators and homelab enthusiasts
- Self-hosting community members
- IT professionals managing virtualized infrastructure
- Users seeking quick deployment of containerized applications

### Use Cases
- Home automation (Home Assistant, Node-RED, ESPHome)
- Media servers (Plex, Jellyfin, Emby)
- Network services (Pi-hole, AdGuard, Unifi Controller)
- Development tools (Docker, Gitea, Jenkins)
- Monitoring and observability (Grafana, Prometheus, Uptime Kuma)
- Database servers (PostgreSQL, MariaDB, MongoDB)
- Web applications (WordPress, Nextcloud, Ghost)
- Infrastructure tools (Nginx Proxy Manager, Traefik, WireGuard)

## Project Mission
Maintain and expand tteck's legacy by providing reliable, secure, and easy-to-use automation scripts for the Proxmox community. 30% of donations support cancer research and hospice care in tteck's memory.

## Supported Platforms
- Proxmox VE 8.4.x and 9.0.x
- Debian-based systems with Proxmox tools
- LXC containers (Alpine, Debian, Ubuntu)
- Virtual machines (various operating systems)
