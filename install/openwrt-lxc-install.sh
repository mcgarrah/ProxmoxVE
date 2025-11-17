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
uci commit uhttpd

# Set root password for web access
echo -e "admin\nadmin" | passwd root

msg_ok "Configured OpenWrt for LXC"

msg_info "Starting OpenWrt services"
/etc/init.d/network restart
/etc/init.d/dropbear start
/etc/init.d/uhttpd start
msg_ok "Started OpenWrt services"

motd_ssh
customize