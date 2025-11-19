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
# Note: OpenWRT uses opkg package manager across all versions (v23, v24, snapshots)
echo "[INFO] Updating OpenWrt packages"
opkg update
opkg list-upgradable | cut -f 1 -d ' ' | xargs -r opkg upgrade
echo "[OK] Updated OpenWrt packages"

echo "[INFO] Installing additional LuCI packages"
# Install base LuCI packages
opkg install luci-mod-admin-full luci-app-attendedsysupgrade || {
    echo "[WARN] Some LuCI packages failed to install, continuing..."
}
echo "[OK] Installed additional LuCI packages"

# Detect OpenWRT version for conditional package installation
OPENWRT_FULL_VERSION=$(grep 'DISTRIB_RELEASE' /etc/openwrt_release 2>/dev/null | cut -d"'" -f2)
OPENWRT_MAJOR=$(echo "$OPENWRT_FULL_VERSION" | cut -d. -f1)
echo "[INFO] Detected OpenWRT version: $OPENWRT_FULL_VERSION (major: $OPENWRT_MAJOR)"

# Install version-appropriate upgrade tool
if [ "$OPENWRT_MAJOR" -ge 24 ] 2>/dev/null; then
    echo "[INFO] Installing owut (OpenWrt v24+ upgrade tool)"
    opkg install owut || echo "[WARN] owut installation failed"
    # v24+ specific packages
    opkg install luci-app-advanced-reboot || echo "[INFO] Advanced reboot not available in this build"
else
    echo "[INFO] Installing auc (OpenWrt v23.x upgrade tool)"
    opkg install auc || echo "[WARN] auc installation failed"
    # Note: luci-app-advanced-reboot is v24+ only, no v23 equivalent
fi

# Restart services after package installation
echo "[INFO] Restarting services"
/etc/init.d/uhttpd restart
echo "[OK] Services restarted"

# Display version information for troubleshooting
echo "[INFO] OpenWRT Configuration Summary:"
echo "  Version: $OPENWRT_FULL_VERSION"
echo "  Kernel: $(uname -r)"
echo "  Architecture: $(uname -m)"
echo "[INFO] OpenWrt LXC configuration completed"

# Version-specific notes
if [ "$OPENWRT_MAJOR" -ge 24 ] 2>/dev/null; then
    echo "[NOTE] OpenWRT v24+ uses Linux 6.6.x kernel and owut upgrade tool"
else
    echo "[NOTE] OpenWRT v23.x uses Linux 5.15.x kernel and auc upgrade tool"
fi
