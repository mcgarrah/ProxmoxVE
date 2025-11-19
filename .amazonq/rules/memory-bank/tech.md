# Technology Stack

## Core Technologies

### Shell Scripting & System Administration
- **Bash/Shell**: Primary scripting language for automation (#!/bin/bash, #!/bin/ash for Alpine)
- **POSIX Compliance**: Cross-platform compatibility across Linux distributions
- **Advanced Shell Features**: Process substitution, parameter expansion, error handling

### Containerization & Virtualization
- **LXC (Linux Containers)**: Lightweight OS-level virtualization
- **Proxmox VE**: Enterprise virtualization platform (versions 8.4.x, 9.0.x)
- **QEMU/KVM**: Hardware virtualization for VM deployments
- **Container Runtimes**: Docker, Podman integration for application containers

### Operating Systems
- **Debian**: Primary base OS (versions 12 Bookworm, 13 Trixie)
- **Alpine Linux**: Lightweight alternative (version 3.22+)
- **Ubuntu**: LTS versions for specific applications (22.04, 24.04)
- **Specialized OS**: OpenWrt, Home Assistant OS, TurnKey Linux

## Web Technologies

### Frontend Stack
- **Next.js 15.5.2**: React-based web framework with App Router
- **React 19.0.0**: Component-based UI library
- **TypeScript 5.8.2**: Type-safe JavaScript development
- **Tailwind CSS 3.4.17**: Utility-first CSS framework
- **Framer Motion 11.18.2**: Animation and interaction library

### UI Components & Libraries
- **Radix UI**: Accessible component primitives
- **Lucide React**: Icon library
- **React Query (TanStack)**: Data fetching and state management
- **Zod**: Schema validation and type safety
- **Sonner**: Toast notifications

### Build Tools & Development
- **Bun**: Fast JavaScript runtime and package manager
- **Vite**: Build tool and development server
- **ESLint**: Code linting and quality assurance
- **Prettier**: Code formatting
- **PostCSS**: CSS processing and optimization

### Backend API
- **Go 1.23.2**: Backend API server language
- **Gorilla Mux**: HTTP router and URL matcher
- **MongoDB Driver**: Database connectivity
- **CORS Support**: Cross-origin resource sharing

## Development Tools & Dependencies

### Package Managers
- **APT**: Debian/Ubuntu package management
- **APK**: Alpine Linux package management
- **NPM/Yarn/PNPM**: Node.js package managers
- **Composer**: PHP dependency management
- **pip/uv**: Python package installation
- **Go Modules**: Go dependency management

### Programming Languages & Runtimes
- **Node.js**: JavaScript runtime (versions 18, 20, 22, 24)
- **Python**: Scripting and application runtime (3.11, 3.12, 3.13)
- **PHP**: Web application runtime (8.1, 8.2, 8.3)
- **Java**: Enterprise application runtime (OpenJDK 11, 17, 21, 25)
- **Ruby**: Application runtime with version management
- **Rust**: Systems programming language
- **Go**: Backend services and utilities

### Database Systems
- **PostgreSQL**: Advanced relational database (versions 13-17)
- **MariaDB/MySQL**: Popular relational database systems
- **MongoDB**: Document-oriented NoSQL database
- **Redis**: In-memory data structure store
- **SQLite**: Embedded database for lightweight applications

### Web Servers & Reverse Proxies
- **Nginx**: High-performance web server and reverse proxy
- **Apache HTTP Server**: Traditional web server
- **Caddy**: Modern web server with automatic HTTPS
- **Traefik**: Cloud-native reverse proxy and load balancer

## Infrastructure & DevOps

### Containerization Tools
- **Docker**: Container platform and runtime
- **Docker Compose**: Multi-container application orchestration
- **Podman**: Daemonless container engine
- **LXC/LXD**: System container management

### Monitoring & Observability
- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Visualization and dashboarding
- **Netdata**: Real-time performance monitoring
- **Zabbix**: Enterprise monitoring solution
- **Uptime Kuma**: Uptime monitoring

### Networking & Security
- **WireGuard**: Modern VPN protocol
- **OpenVPN**: Traditional VPN solution
- **Pi-hole**: Network-level ad blocking
- **AdGuard Home**: DNS filtering and protection
- **Fail2ban**: Intrusion prevention system

### Build & Deployment
- **GitHub Actions**: CI/CD automation
- **Git**: Version control system
- **Bash**: Deployment scripting
- **Systemd**: Service management
- **Cron**: Task scheduling

## System Requirements

### Proxmox VE Compatibility
- **Supported Versions**: 8.4.x, 9.0.x
- **Minimum Hardware**: 4GB RAM, 32GB storage
- **Network Requirements**: Internet connectivity for downloads
- **Architecture**: x86_64 (AMD64), ARM64 support for select applications

### Container Requirements
- **LXC Features**: Nested virtualization support for Docker
- **Resource Allocation**: Dynamic CPU and memory scaling
- **Storage**: ZFS, LVM, directory-based storage backends
- **Networking**: Bridge, VLAN, and overlay network support

### Development Environment
- **Node.js**: Version 18+ for frontend development
- **Go**: Version 1.21+ for API development
- **Git**: Version control and contribution workflow
- **Shell**: Bash 4.0+ for script development

## External Dependencies & APIs

### Package Repositories
- **Debian/Ubuntu**: Official and third-party repositories
- **Alpine**: Community and edge repositories
- **Docker Hub**: Container image registry
- **GitHub Releases**: Application binary downloads

### Third-Party Services
- **GitHub API**: Release information and downloads
- **Docker Registry**: Container image distribution
- **CDN Services**: Fast content delivery
- **DNS Services**: Domain resolution and management

### Application-Specific Dependencies
- **FFmpeg**: Media processing and transcoding
- **ImageMagick**: Image manipulation and processing
- **Chromium/Chrome**: Web scraping and automation
- **Git**: Source code management
- **OpenSSL**: Cryptographic operations

## Version Management & Updates

### Automated Updates
- **GitHub Release Tracking**: Automatic detection of new versions
- **Package Manager Integration**: System-level updates
- **Application Updates**: In-place upgrade mechanisms
- **Rollback Capabilities**: Safe update procedures

### Version Pinning
- **Stable Releases**: Production-ready versions
- **LTS Support**: Long-term support versions
- **Security Updates**: Critical patch management
- **Compatibility Testing**: Cross-version validation

This technology stack provides a robust foundation for deploying and managing hundreds of different applications while maintaining consistency, security, and ease of use across the entire ecosystem.