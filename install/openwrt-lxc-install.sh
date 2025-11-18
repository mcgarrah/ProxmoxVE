#!/bin/ash

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

msg_info "Configuring OpenWrt for LXC"

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

msg_ok "Configured OpenWrt for LXC"

msg_info "Starting OpenWrt services"
/etc/init.d/network restart
/etc/init.d/dropbear start
/etc/init.d/uhttpd start
msg_ok "Started OpenWrt services"

# Update packages and install additional components
msg_info "Updating OpenWrt packages"
opkg update
opkg list-upgradable | cut -f 1 -d ' ' | xargs -r opkg upgrade
msg_ok "Updated OpenWrt packages"

msg_info "Installing additional LuCI packages"
opkg install luci-mod-admin-full luci-app-attendedsysupgrade auc || {
    msg_warn "Some packages failed to install, continuing..."
}
msg_ok "Installed additional LuCI packages"

# Restart services after package installation
msg_info "Restarting services"
/etc/init.d/uhttpd restart
msg_ok "Services restarted"

motd_ssh
customize