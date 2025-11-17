#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
# Set install URL if provided (used for development) - must be set before sourcing build.func
var_install_url="${var_install_url:-}"

# Set base URL for repository access
if [ -n "$var_install_url" ]; then
  # var_install_url should be the base repo URL, not including /install
  BASE_URL="$var_install_url"
elif [ -n "$REPO" ]; then
  BASE_URL="https://raw.githubusercontent.com/$REPO"
else
  BASE_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main"
fi
source <(curl -fsSL ${BASE_URL}/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openwrt.org/

APP="OpenWrt-Debian-LXC"
var_tags="${var_tags:-router;networking}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-0}"
var_hwaccel="${var_hwaccel:-0}"
var_vaapi="${var_vaapi:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  msg_info "Updating OpenWrt LXC"
  
  if [[ -f /etc/openwrt-release ]]; then
    msg_info "Updating OpenWrt packages"
    opkg update
    opkg list-upgradable | cut -f 1 -d ' ' | xargs -r opkg upgrade
    msg_ok "Updated OpenWrt packages"
  else
    msg_info "Updating Debian packages"
    $STD apt-get update
    $STD apt-get -y upgrade
    msg_ok "Updated Debian packages"
  fi
  
  exit 0
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access OpenWrt LuCI interface using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW} Default credentials: root / (no password)${CL}"