# Proxmox SDN DNS Integration Plan

## 🎯 **Objective**

Automatically configure PowerDNS as a DNS provider in Proxmox SDN during LXC installation, eliminating manual configuration steps and reducing setup complexity.

## 📋 **Current Manual Process**

Users currently need to:
1. Install PowerDNS LXC container
2. Copy API key, URL, TTL, and SSL fingerprint from installation output
3. Navigate to Proxmox web interface → Datacenter → SDN → DNS
4. Manually add DNS provider with copied values
5. Apply SDN configuration changes

## 🚀 **Proposed Automation**

### **Interactive Installation Options**

Add new environment variables and prompts:
- `var_sdn_dns_enabled` - Enable automatic SDN DNS configuration
- `var_sdn_apply_changes` - Automatically apply SDN changes after configuration
- `var_proxmox_node` - Target Proxmox node (auto-detect if possible)

### **Implementation Variables**

```bash
# New environment variables
SDN_DNS_ENABLED=${var_sdn_dns_enabled:-false}
SDN_APPLY_CHANGES=${var_sdn_apply_changes:-false}
PROXMOX_NODE=${var_proxmox_node:-$(hostname)}
DNS_PROVIDER_ID=${var_hostname:-powerdns}  # Use LXC hostname as DNS ID
```

## 🔧 **Technical Implementation**

### **1. Proxmox API Integration**

**API Endpoints Required:**
```bash
# Add DNS provider
PUT /api2/json/cluster/sdn/dns/{dns_id}

# Apply SDN configuration
PUT /api2/json/cluster/sdn
```

**API Authentication:**
- Use Proxmox host's root credentials or API tokens
- Validate permissions for SDN configuration access

### **2. DNS Provider Configuration**

**Required Parameters:**
```json
{
  "type": "powerdns",
  "url": "https://CONTAINER_IP:8443/api/v1/servers/localhost",
  "key": "GENERATED_API_KEY",
  "ttl": 300
}
```

**SSL Certificate Handling:**
- Extract SHA256 fingerprint from generated certificate
- Configure Proxmox to accept self-signed certificate

### **3. Installation Flow Integration**

**New Interactive Prompts:**
```bash
# After PowerDNS installation completes
if [[ "$ROLE" == "a" || "$ROLE" == "b" ]]; then
  read -r -p "Configure PowerDNS in Proxmox SDN automatically? [y/N] " SDN_DNS_ENABLED
  
  if [[ "${SDN_DNS_ENABLED,,}" =~ ^(y|yes)$ ]]; then
    read -r -p "Apply SDN configuration changes immediately? [y/N] " SDN_APPLY_CHANGES
    read -r -p "Proxmox node name [$(hostname)] " PROXMOX_NODE
    PROXMOX_NODE=${PROXMOX_NODE:-$(hostname)}
  fi
fi
```

## 📝 **Implementation Steps**

### **Phase 1: API Research & Validation**
- [ ] Research Proxmox SDN API endpoints and authentication methods
- [ ] Test API calls for DNS provider configuration
- [ ] Validate required permissions and access levels
- [ ] Test SSL certificate fingerprint handling

### **Phase 2: Core Implementation**
- [ ] Add new environment variables and interactive prompts
- [ ] Implement Proxmox API client functions
- [ ] Add DNS provider configuration logic
- [ ] Implement error handling and validation

### **Phase 3: Integration & Testing**
- [ ] Integrate SDN configuration into installation flow
- [ ] Add optional automatic SDN changes application
- [ ] Test with various Proxmox versions and configurations
- [ ] Add comprehensive error messages and troubleshooting

### **Phase 4: Documentation & Polish**
- [ ] Update JSON configuration with new options
- [ ] Add installation output for SDN configuration status
- [ ] Update user documentation and examples
- [ ] Add rollback mechanisms for failed configurations

## 🔍 **API Research Requirements**

### **Proxmox API Investigation**
```bash
# Commands to research:
pvesh get /cluster/sdn/dns
pvesh create /cluster/sdn/dns --dns powerdns --type powerdns --url https://IP:8443/api/v1/servers/localhost --key API_KEY
pvesh set /cluster/sdn
```

### **Authentication Methods**
- Root user authentication
- API token authentication  
- Permission requirements for SDN configuration

### **Error Handling Scenarios**
- Proxmox API unavailable
- Insufficient permissions
- Network connectivity issues
- Invalid SSL certificates
- SDN configuration conflicts

## 🎛️ **Configuration Options**

### **Environment Variables**
```bash
# Enable SDN DNS integration
var_sdn_dns_enabled=true

# Automatically apply changes
var_sdn_apply_changes=true

# Custom DNS provider ID (defaults to hostname)
var_dns_provider_id=my-powerdns

# Proxmox node name (auto-detect if not specified)
var_proxmox_node=pve-node1
```

### **Interactive Prompts**
```bash
Configure PowerDNS in Proxmox SDN automatically? [y/N]
DNS Provider ID [container-hostname]: 
Apply SDN configuration changes immediately? [y/N]
Proxmox node name [auto-detected]: 
```

## 📊 **Expected Benefits**

### **User Experience**
- ✅ Zero manual configuration required
- ✅ Immediate SDN integration
- ✅ Reduced setup complexity
- ✅ Fewer configuration errors

### **Technical Benefits**
- ✅ Consistent DNS provider naming
- ✅ Automatic SSL certificate handling
- ✅ Validated API connectivity
- ✅ Optional immediate activation

## ⚠️ **Considerations & Risks**

### **Security Considerations**
- API authentication and permission validation
- SSL certificate trust and fingerprint verification
- Network access between container and Proxmox host

### **Compatibility Concerns**
- Proxmox VE version compatibility
- SDN feature availability
- API endpoint stability across versions

### **Error Recovery**
- Failed API calls and rollback procedures
- Network connectivity issues
- Permission denied scenarios
- Conflicting DNS provider configurations

## 🧪 **Testing Strategy**

### **Test Scenarios**
1. **Fresh Installation**: New PowerDNS container with SDN integration
2. **Existing SDN**: Container installation with existing DNS providers
3. **Permission Issues**: Limited API access scenarios
4. **Network Problems**: Connectivity issues between container and host
5. **Version Compatibility**: Different Proxmox VE versions

### **Validation Points**
- DNS provider appears in Proxmox SDN configuration
- API connectivity test succeeds
- SSL certificate fingerprint matches
- SDN changes apply successfully (if enabled)
- Error messages are clear and actionable

---

## 🎯 **Next Steps**

1. **Research Phase**: Investigate Proxmox SDN API endpoints and authentication
2. **Prototype**: Create minimal API integration proof of concept
3. **Implementation**: Add full SDN integration to PowerDNS installation script
4. **Testing**: Validate across different Proxmox configurations
5. **Documentation**: Update all relevant documentation and examples

---

*This feature will significantly improve the PowerDNS installation experience by eliminating manual SDN configuration steps and providing seamless Proxmox integration.*