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
echo "Debug: Starting template creation check"

# Create OpenWRT template if it doesn't exist
create_openwrt_template() {
  echo "Debug: Entering create_openwrt_template function"
  local template_name="openwrt-24.10.4-lxc_amd64.tar.gz"
  local template_path="/var/lib/vz/template/cache/$template_name"
  
  echo "Debug: Checking if template exists at: $template_path"
  if [ ! -f "$template_path" ]; then
    echo "Debug: Template not found, creating it"
    echo "Debug: BASE_URL is: $BASE_URL"
    
    # Test if we can reach the template creation script
    echo "Debug: Testing curl access to template script"
    if ! curl -fsSL --connect-timeout 10 "${BASE_URL}/misc/create-openwrt-template.sh" >/dev/null; then
      echo "Error: Cannot access template creation script at ${BASE_URL}/misc/create-openwrt-template.sh"
      exit 1
    fi
    echo "Debug: Template script is accessible"
    
    echo "Debug: Starting template creation with timeout"
    # Use timeout to prevent hanging
    if ! timeout 300 bash <(curl -fsSL ${BASE_URL}/misc/create-openwrt-template.sh); then
      echo "Error: Failed to create OpenWRT template (timeout or error)"
      exit 1
    fi
    echo "Debug: Template creation script completed"
    
    # Verify template was created successfully
    if [ ! -f "$template_path" ]; then
      echo "Error: Template creation completed but file not found at $template_path"
      exit 1
    fi
    
    # Verify template is not empty
    if [ ! -s "$template_path" ]; then
      echo "Error: Template file is empty: $template_path"
      exit 1
    fi
    
    echo "Debug: Template created successfully"
  else
    echo "Debug: Using existing template: $template_name"
  fi
  
  echo "Debug: Exiting create_openwrt_template function"
  echo "$template_name"
}

APP="OpenWrt"
var_tags="${var_tags:-router;networking;firewall}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-8}"
var_os="unmanaged"
var_version="24.10.4"
var_unprivileged="${var_unprivileged:-0}"
var_hwaccel="${var_hwaccel:-0}"
var_vaapi="${var_vaapi:-0}"
header_info "$APP"
variables
color
catch_errors

# Set template path (after build.func is loaded)
echo "Debug: About to create template"
TEMPLATE_NAME=$(create_openwrt_template)
echo "Debug: Template creation completed: $TEMPLATE_NAME"
var_template="$TEMPLATE_NAME"

# Set container variables
CT_ID=${var_ctid:-$(pvesh get /cluster/nextid)}
HN=${var_hostname:-openwrt}
DISK_SIZE="$var_disk"
CORE_COUNT="$var_cpu"
RAM_SIZE="$var_ram"
BRG="vmbr0"
NET="dhcp"
TAGS="community-script;${var_tags}"

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

function build_openwrt_container() {
  # Get storage selections
  source <(curl -fsSL ${BASE_URL}/misc/tools.func)
  
  # Select template storage
  msg_info "Selecting template storage"
  TEMPLATE_STORAGE="cephfs"  # Use your template storage
  
  # Select container storage  
  msg_info "Selecting container storage"
  CONTAINER_STORAGE="cephrbd"  # Use your container storage
  
  msg_info "Creating OpenWRT LXC Container"
  
  # Build network string
  NET_STRING="name=eth0,bridge=$BRG,ip=$NET"
  
  # Debug: Show what we're about to execute
  echo "Debug: Template path: $TEMPLATE_STORAGE:vztmpl/$var_template"
  echo "Debug: Template path length: $(echo "$TEMPLATE_STORAGE:vztmpl/$var_template" | wc -c)"
  
  # Create container directly with pct
  if ! pct create "$CT_ID" "$TEMPLATE_STORAGE:vztmpl/$var_template" \
    --hostname "$HN" \
    --memory "$RAM_SIZE" \
    --cores "$CORE_COUNT" \
    --rootfs "$CONTAINER_STORAGE:$DISK_SIZE" \
    --net0 "$NET_STRING" \
    --unprivileged 0 \
    --ostype unmanaged \
    --features "nesting=1" \
    --tags "$TAGS" \
    --onboot 1; then
    msg_error "Container creation failed"
    exit 1
  fi
  
  msg_ok "Created LXC Container $CT_ID"
  
  # Start container
  msg_info "Starting LXC Container"
  pct start "$CT_ID"
  msg_ok "Started LXC Container"
  
  # Get container IP
  sleep 5
  IP=$(pct exec "$CT_ID" ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1)
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

# Skip the standard build system and call our custom function directly
# TODO: Alternative approach - create misc/create_openwrt_lxc.sh script
# This would mirror misc/create-openwrt-template.sh and provide
# OpenWRT-specific container creation logic separate from main create_lxc.sh
build_openwrt_container

# Set IP for description
IP=$(pct exec "$CT_ID" ip a s dev eth0 | awk '/inet / {print $2}' | cut -d/ -f1 2>/dev/null || echo "DHCP")

# Set CTID for final output
CTID="$CT_ID"

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access OpenWrt LuCI interface using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW} Default credentials: root / (no password)${CL}"
echo -e "${INFO}${YW} SSH Access: ssh root@${IP}${CL}"
echo -e "${INFO}${YW} Console Access: pct enter ${CTID}${CL}"