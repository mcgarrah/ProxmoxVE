#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openwrt.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  wget \
  gnupg \
  ca-certificates \
  bridge-utils \
  iptables \
  kmod \
  udev \
  systemd
msg_ok "Installed Dependencies"

msg_info "Setting up OpenWrt repository"
# Add OpenWrt repository key and source
wget -qO- https://downloads.openwrt.org/releases/packages-23.05/x86_64/packages/Packages.gz | gunzip > /tmp/packages
OPENWRT_VERSION=$(curl -s https://api.github.com/repos/openwrt/openwrt/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")' | sed 's/^v//')
if [[ -z "$OPENWRT_VERSION" ]]; then
  OPENWRT_VERSION="23.05.5"
fi
msg_ok "OpenWrt version: $OPENWRT_VERSION"

msg_info "Installing OpenWrt rootfs"
# Download and extract OpenWrt rootfs
cd /tmp
ROOTFS_URL="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/x86/64/openwrt-${OPENWRT_VERSION}-x86-64-rootfs.tar.gz"
wget -q "$ROOTFS_URL" -O openwrt-rootfs.tar.gz

# Create OpenWrt environment
mkdir -p /opt/openwrt
tar -xzf openwrt-rootfs.tar.gz -C /opt/openwrt --strip-components=0
msg_ok "Installed OpenWrt rootfs"

msg_info "Configuring OpenWrt in LXC"
# Create chroot wrapper script
cat <<'EOF' > /usr/local/bin/openwrt-chroot
#!/bin/bash
mount --bind /proc /opt/openwrt/proc 2>/dev/null || true
mount --bind /sys /opt/openwrt/sys 2>/dev/null || true  
mount --bind /dev /opt/openwrt/dev 2>/dev/null || true
chroot /opt/openwrt "$@"
EOF
chmod +x /usr/local/bin/openwrt-chroot

# Create OpenWrt service
cat <<'EOF' > /etc/systemd/system/openwrt.service
[Unit]
Description=OpenWrt in LXC
After=network.target

[Service]
Type=forking
ExecStart=/usr/local/bin/openwrt-start
ExecStop=/usr/local/bin/openwrt-stop
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Create start/stop scripts
cat <<'EOF' > /usr/local/bin/openwrt-start
#!/bin/bash
# Mount necessary filesystems
mount --bind /proc /opt/openwrt/proc 2>/dev/null || true
mount --bind /sys /opt/openwrt/sys 2>/dev/null || true
mount --bind /dev /opt/openwrt/dev 2>/dev/null || true

# Start OpenWrt services in chroot
chroot /opt/openwrt /sbin/procd &
sleep 2
chroot /opt/openwrt /etc/init.d/network start
chroot /opt/openwrt /etc/init.d/uhttpd start
EOF

cat <<'EOF' > /usr/local/bin/openwrt-stop
#!/bin/bash
# Stop OpenWrt services
chroot /opt/openwrt /etc/init.d/uhttpd stop 2>/dev/null || true
chroot /opt/openwrt /etc/init.d/network stop 2>/dev/null || true
killall procd 2>/dev/null || true

# Unmount filesystems
umount /opt/openwrt/proc 2>/dev/null || true
umount /opt/openwrt/sys 2>/dev/null || true
umount /opt/openwrt/dev 2>/dev/null || true
EOF

chmod +x /usr/local/bin/openwrt-start /usr/local/bin/openwrt-stop
msg_ok "Configured OpenWrt service"

msg_info "Setting up OpenWrt network configuration"
# Create network config file if it doesn't exist
if [ ! -f /opt/openwrt/etc/config/network ]; then
  cat > /opt/openwrt/etc/config/network << 'EOF'
config interface 'loopback'
	option ifname 'lo'
	option proto 'static'
	option ipaddr '127.0.0.1'
	option netmask '255.0.0.0'

config interface 'lan'
	option proto 'static'
	option ipaddr '192.168.1.1'
	option netmask '255.255.255.0'
	option device 'eth0'
EOF
else
  # Update existing config
  openwrt-chroot uci set network.lan.proto='static'
  openwrt-chroot uci set network.lan.ipaddr='192.168.1.1'
  openwrt-chroot uci set network.lan.netmask='255.255.255.0'
  openwrt-chroot uci set network.lan.device='eth0'
  openwrt-chroot uci commit network
fi

# Enable and configure LuCI web interface
openwrt-chroot uci set uhttpd.main.listen_http='0.0.0.0:80'
openwrt-chroot uci set uhttpd.main.listen_https='0.0.0.0:443'
openwrt-chroot uci commit uhttpd
msg_ok "Configured OpenWrt network"

msg_info "Enabling OpenWrt service"
systemctl enable openwrt.service
systemctl start openwrt.service
msg_ok "Started OpenWrt service"

msg_info "Creating convenience aliases"
cat <<'EOF' >> /root/.bashrc

# OpenWrt LXC aliases
alias openwrt='openwrt-chroot'
alias owrt='openwrt-chroot'
alias luci='echo "Access LuCI at: http://$(hostname -I | awk "{print \$1}")"'
EOF
msg_ok "Created convenience aliases"

motd_ssh
customize