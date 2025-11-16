# PowerDNS Production Release TODO

## 🚨 **Critical Fixes (Must Fix Before Release)**

- [ ] **Fix PowerDNS Webserver Timing Issue**
  - Add service restart after configuration changes
  - Implement port 8081 validation with retry logic
  - Ensure API is responding before proceeding

- [ ] **Fix Pre-Installation Configuration Flow**
  - Move ALL prompts to ct/powerdns.sh (before container creation)
  - Set CPU/RAM based on PowerDNS-Admin choice upfront
  - Always install nginx (required for both API and web interface TLS)

- [ ] **Fix PowerDNS-Admin Integration**
  - Ensure admin/admin user is created automatically
  - Auto-register PowerDNS API server in PowerDNS-Admin
  - Validate PowerDNS server appears on first login
  - Fix Flask database initialization timing issues

- [ ] **Create Static Website Landing Page**
  - Serve static website on HTTPS port 443 via nginx
  - Include links to PowerDNS API (port 8443) and PowerDNS-Admin (port 9443)
  - Add service descriptions and status information
  - Provide single entry point for all PowerDNS services

- [ ] **Consolidate TLS Certificates**
  - Use single shared self-signed certificate for all nginx services
  - Replace separate certificates with unified certificate management
  - Update all nginx sites to use shared certificate
  - Generate certificate with multiple SANs for hostname and IP

## 🔧 **High Priority Features**

- [ ] **Dynamic Login Banner (MOTD)**
  - Show service status, ports, API keys, URLs on login
  - Include Proxmox SDN integration parameters
  - Role-based information display

- [ ] **Proxmox SDN Integration**
  - Automatically configure PowerDNS in Proxmox SDN
  - Use LXC hostname as DNS provider ID
  - Optional automatic application of SDN changes

- [ ] **Let's Encrypt TLS Certificates**
  - Investigate replacing self-signed certificates with Let's Encrypt
  - Resolve DNS chicken-and-egg problem (need DNS for ACME validation)
  - Implement HTTP-01 or DNS-01 challenge methods
  - Add automatic certificate renewal with certbot

## 🚀 **Nice-to-Have Features**

- [ ] **Enhanced Authentication Options**
  - LDAP/Active Directory integration
  - 2FA/TOTP support
  - OAuth providers (Google, GitHub, Azure)

- [ ] **Advanced Database Support**
  - MySQL/MariaDB option
  - PostgreSQL option
  - Database connection pooling

- [ ] **Monitoring & Logging**
  - Enhanced logging configuration
  - Performance monitoring integration
  - Health check endpoints

## 🛠 **Technical Debt**

- [ ] **Comprehensive Error Handling**
  - Add error handling for all operations
  - Implement configuration validation
  - Add rollback mechanisms for failed installations

- [ ] **Documentation**
  - Create comprehensive installation guide
  - Add troubleshooting documentation
  - Document all configuration options

---

## 📋 **Release Readiness Checklist**

### **Must Complete (Blocking)**
1. ✅ TLS for PowerDNS-Admin (COMPLETED)
2. ❌ PowerDNS webserver timing fix
3. ❌ Pre-installation configuration flow
4. ❌ PowerDNS-Admin integration (admin user + API registration)
5. ❌ Static website landing page (port 443)
6. ❌ Consolidate TLS certificates (shared certificate)

### **Should Complete (High Value)**
7. ❌ Dynamic login banner
8. ❌ Proxmox SDN integration
9. ❌ Let's Encrypt TLS certificates

### **Could Complete (If Time Permits)**
10. ❌ Enhanced error handling
11. ❌ Comprehensive documentation

---

**Target: Complete items 1-6 for production release**