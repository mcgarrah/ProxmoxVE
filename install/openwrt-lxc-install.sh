#!/bin/ash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openwrt.org/

echo "[INFO] Configuring OpenWrt for LXC"

# Configure network interface for LXC
uci set network.lan.proto='dhcp'
uci set network.lan.device='eth0'
uci commit network

# Enable SSH access
uci set dropbear.@dropbear[0].PasswordAuth='on'
uci set dropbear.@dropbear[0].RootPasswordAuth='on'
uci set dropbear.@dropbear[0].Port='22'
uci commit dropbear

# Configure LuCI web interface
uci set uhttpd.main.listen_http='0.0.0.0:80'
uci set uhttpd.main.listen_https='0.0.0.0:443'
uci set uhttpd.main.redirect_https='0'
uci set uhttpd.main.rfc1918_filter='0'
uci commit uhttpd

# Configure system settings
uci set system.@system[0].hostname='openwrt-lxc'
uci set system.@system[0].timezone='UTC'
uci commit system

# Set up firewall for LXC environment
uci set firewall.@defaults[0].input='ACCEPT'
uci set firewall.@defaults[0].output='ACCEPT'
uci set firewall.@defaults[0].forward='ACCEPT'
uci commit firewall

# Create runtime directories
mkdir -p /var/lock /var/run /tmp/luci-sessions

echo "[OK] Configured OpenWrt for LXC"

echo "[INFO] Starting OpenWrt services"
/etc/init.d/network restart
/etc/init.d/dropbear start
/etc/init.d/uhttpd start
echo "[OK] Started OpenWrt services"

# Update packages and install additional components
echo "[INFO] Updating OpenWrt packages"
opkg update
opkg list-upgradable | cut -f 1 -d ' ' | xargs -r opkg upgrade
echo "[OK] Updated OpenWrt packages"

echo "[INFO] Installing additional LuCI packages"
opkg install luci-mod-admin-full luci-app-attendedsysupgrade owut || {
    echo "[WARN] Some packages failed to install, continuing..."
}
echo "[OK] Installed additional LuCI packages"

# Restart services after package installation
echo "[INFO] Restarting services"
/etc/init.d/uhttpd restart
echo "[OK] Services restarted"

echo "[INFO] OpenWrt LXC configuration completed"
