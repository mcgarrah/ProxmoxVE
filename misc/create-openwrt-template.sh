#!/usr/bin/env bash

# OpenWRT LXC Template Creator
# Creates native OpenWRT LXC template from official rootfs

set -e

# Get latest stable OpenWRT version (24.x or newer)
echo "Fetching latest OpenWRT version..."
OPENWRT_VERSION=$(curl -s https://downloads.openwrt.org/releases/ | \
  grep -oE 'href="[0-9]+\.[0-9]+\.[0-9]+/"' | \
  sed 's/href="//;s/\/"//' | \
  sort -V | \
  awk -F. '$1 >= 24 {print}' | \
  tail -1)

if [ -z "$OPENWRT_VERSION" ]; then
  echo "Failed to fetch latest version, falling back to 24.10.4"
  OPENWRT_VERSION="24.10.4"
fi

TEMPLATE_NAME="openwrt-${OPENWRT_VERSION}-lxc_amd64.tar.gz"
WORK_DIR="/tmp/openwrt-template-$$"

echo "Creating OpenWRT ${OPENWRT_VERSION} LXC Template..."

# Create working directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Download OpenWRT rootfs
echo "Downloading OpenWRT rootfs..."
wget -q "https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/x86/64/openwrt-${OPENWRT_VERSION}-x86-64-rootfs.tar.gz" -O openwrt-rootfs.tar.gz

# Extract rootfs
echo "Extracting rootfs..."
mkdir openwrt-template
tar -xzf openwrt-rootfs.tar.gz -C openwrt-template

cd openwrt-template

# Configure for LXC environment
echo "Configuring for LXC..."

# Set hostname
echo "openwrt-lxc" > etc/hostname

# Configure hosts file
cat > etc/hosts << 'EOF'
127.0.0.1 localhost openwrt-lxc
::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# Configure network for LXC (DHCP by default)
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

# Enable SSH by default
uci_set() {
    local config="$1"
    local section="$2" 
    local option="$3"
    local value="$4"
    
    # Simple UCI set implementation for template creation
    if [ ! -f "etc/config/$config" ]; then
        mkdir -p etc/config
        touch "etc/config/$config"
    fi
    
    # Add basic SSH configuration
    if [ "$config" = "dropbear" ]; then
        cat > etc/config/dropbear << 'EOF'
config dropbear
	option PasswordAuth 'on'
	option RootPasswordAuth 'on'
	option Port '22'
EOF
    fi
}

# Configure SSH
uci_set dropbear '@dropbear[0]' PasswordAuth 'on'
uci_set dropbear '@dropbear[0]' RootPasswordAuth 'on'
uci_set dropbear '@dropbear[0]' Port '22'

# Configure LuCI web interface
# TODO: Add option for forced HTTPS redirection (redirect_https '1')
cat > etc/config/uhttpd << 'EOF'
config uhttpd 'main'
	option listen_http '0.0.0.0:80'
	option listen_https '0.0.0.0:443'
	option home '/www'
	option rfc1918_filter '0'
	option redirect_https '0'
	option max_requests '3'
	option max_connections '100'
	option cert '/etc/uhttpd.crt'
	option key '/etc/uhttpd.key'
	option cgi_prefix '/cgi-bin'
	option lua_prefix '/cgi-bin/luci=/usr/lib/lua/luci/sgi/uhttpd.lua'
	option script_timeout '60'
	option network_timeout '30'
	option http_keepalive '20'
	option tcp_keepalive '1'
EOF

# Configure system settings for LXC
cat > etc/config/system << 'EOF'
config system
	option hostname 'openwrt-lxc'
	option timezone 'UTC'
	option ttylogin '0'
	option log_size '64'
	option urandom_seed '0'

config timeserver 'ntp'
	list server '0.openwrt.pool.ntp.org'
	list server '1.openwrt.pool.ntp.org'
	list server '2.openwrt.pool.ntp.org'
	list server '3.openwrt.pool.ntp.org'
	option enabled '1'
	option enable_server '0'
EOF

# Configure firewall for LXC environment
cat > etc/config/firewall << 'EOF'
config defaults
	option syn_flood '1'
	option input 'ACCEPT'
	option output 'ACCEPT'
	option forward 'ACCEPT'

config zone
	option name 'lan'
	list network 'lan'
	option input 'ACCEPT'
	option output 'ACCEPT'
	option forward 'ACCEPT'
EOF

# Create init script for LXC startup
cat > etc/init.d/lxc-setup << 'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=10

start() {
    # Ensure services start properly in LXC
    /etc/init.d/network restart
    /etc/init.d/dropbear start
    /etc/init.d/uhttpd start
}

stop() {
    /etc/init.d/uhttpd stop
    /etc/init.d/dropbear stop
}
EOF

chmod +x etc/init.d/lxc-setup

# Enable the LXC setup service
ln -sf ../init.d/lxc-setup etc/rc.d/S99lxc-setup

# Create template archive
echo "Creating template archive..."
cd ..
tar -czf "../${TEMPLATE_NAME}" -C openwrt-template .

# Move to final location
mv "../${TEMPLATE_NAME}" "/var/lib/vz/template/cache/${TEMPLATE_NAME}"

# Cleanup
cd /
rm -rf "$WORK_DIR"

echo "OpenWRT LXC template created: /var/lib/vz/template/cache/${TEMPLATE_NAME}"
echo "Template size: $(du -h /var/lib/vz/template/cache/${TEMPLATE_NAME} | cut -f1)"
echo ""
echo "Usage:"
echo "  pct create 999 /var/lib/vz/template/cache/${TEMPLATE_NAME} --hostname openwrt --memory 256 --cores 1 --rootfs local:8 --net0 name=eth0,bridge=vmbr0,ip=dhcp --unprivileged 0"