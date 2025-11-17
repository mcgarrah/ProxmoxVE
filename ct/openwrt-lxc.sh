#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: community-scripts
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://openwrt.org/

source <(curl -fsSL ${BASE_URL:-https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main}/misc/build.func)
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
var_disk="8"
var_cpu="1"
var_ram="256"
var_os="openwrt"
var_version="24.10.4"
# Set template path
var_template=$(create_openwrt_template)
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
if [[ ! -f /usr/bin/opkg ]]; then
  msg_error "No ${APP} Installation Found!"
  exit
fi
msg_info "Updating OpenWrt Packages"
opkg update &>/dev/null
opkg upgrade &>/dev/null
msg_ok "Updated $APP LXC Container"
exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}${CL} \n"