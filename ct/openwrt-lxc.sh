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
# color
# verb_ip6
# catch_errors
# setting_up_container
# network_check
# update_os

function header_info {
clear
cat <<"EOF"
   ____                   _       _______ 
  / __ \                 | |     |__   __|
 | |  | |_ __   ___ _ __ | |        | |   
 | |  | | '_ \ / _ \ '_ \| |        | |   
 | |__| | |_) |  __/ | | | |____    | |   
  \____/| .__/ \___|_| |_|______|   |_|   
        | |                              
        |_|    Native LXC Container      
                                         
EOF
}

header_info
echo -e "Loading..."

# Create OpenWRT template if it doesn't exist
create_openwrt_template() {
  local template_name="openwrt-24.10.4-lxc_amd64.tar.gz"
  local template_path="/var/lib/vz/template/cache/$template_name"
  
  if [ ! -f "$template_path" ]; then
    msg_info "Creating OpenWRT LXC template"
    bash <(curl -fsSL ${BASE_URL}/misc/create-openwrt-template.sh)
    msg_ok "Created OpenWRT LXC template"
  fi
  
  echo "$template_name"
}

APP="OpenWrt"
var_tags="${var_tags:-router;networking;firewall}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-8}"
var_os="openwrt"
var_version="24.10.4"
var_unprivileged="${var_unprivileged:-0}"
var_hwaccel="${var_hwaccel:-0}"
var_vaapi="${var_vaapi:-0}"
# Set template path
var_template=$(create_openwrt_template)

header_info "$APP"
variables
color
catch_errors

function default_settings() {
  CT_TYPE="0"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}

function update_script() {
  header_info
  msg_info "Updating $APP LXC Container"
  
  if [[ -f /etc/openwrt-release ]]; then
    msg_info "Updating OpenWrt packages"
    opkg update &>/dev/null
    opkg list-upgradable | cut -f 1 -d ' ' | xargs -r opkg upgrade &>/dev/null
    msg_ok "Updated OpenWrt packages"
  else
    msg_error "No ${APP} Installation Found!"
    exit 1
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
echo -e "${INFO}${YW} SSH Access: ssh root@${IP}${CL}"
echo -e "${INFO}${YW} Console Access: pct enter ${CTID}${CL}"