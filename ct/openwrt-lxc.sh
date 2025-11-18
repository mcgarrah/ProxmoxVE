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



header_info
echo -e "Loading..."
echo "Debug: Starting template creation check"

# Create OpenWRT template if it doesn't exist
create_openwrt_template() {
  echo "Debug: Entering create_openwrt_template function"
  
  # Get latest OpenWRT version (24.x or newer)
  local openwrt_version=$(curl -s https://downloads.openwrt.org/releases/ | \
    grep -oE 'href="[0-9]+\.[0-9]+\.[0-9]+/"' | \
    sed 's/href="//;s/\/"//' | \
    sort -V | \
    awk -F. '$1 >= 24 {print}' | \
    tail -1)
  
  if [ -z "$openwrt_version" ]; then
    echo "Debug: Failed to fetch latest version, using fallback"
    openwrt_version="24.10.4"
  fi
  
  local template_name="openwrt-${openwrt_version}-lxc_amd64.tar.gz"
  local template_path="/var/lib/vz/template/cache/$template_name"
  
  echo "Debug: Using OpenWRT version: $openwrt_version"
  
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
var_template=$(create_openwrt_template)
echo "Debug: Template creation completed: $var_template"

# Set base settings - network config will come from build system
base_settings

# Override container variables after base_settings
CT_ID=${CT_ID:-$(pvesh get /cluster/nextid)}
HN=${HN:-openwrt-lxc}
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
  # Get storage selections using the same logic as create_lxc.sh
  source <(curl -fsSL ${BASE_URL}/misc/tools.func)
  
  # Function to select storage (copied from create_lxc.sh logic)
  select_storage() {
    local CLASS=$1 CONTENT CONTENT_LABEL
    case $CLASS in
      template) CONTENT='vztmpl'; CONTENT_LABEL='Template' ;;
      container) CONTENT='rootdir'; CONTENT_LABEL='Container' ;;
    esac
    
    local -a MENU
    while read -r TAG TYPE _ TOTAL USED FREE _; do
      [[ -n "$TAG" && -n "$TYPE" ]] || continue
      local USED_FMT=$(numfmt --to=iec --from-unit=K --format %.1f <<<"$USED")
      local FREE_FMT=$(numfmt --to=iec --from-unit=K --format %.1f <<<"$FREE")
      MENU+=("$TAG" "Free: ${FREE_FMT}B Used: ${USED_FMT}B" "OFF")
    done < <(pvesm status -content "$CONTENT" | awk 'NR>1')
    
    if [ ${#MENU[@]} -eq 3 ]; then
      STORAGE_RESULT="${MENU[0]}"
    else
      STORAGE_RESULT=$(whiptail --backtitle "Proxmox VE Helper Scripts" \
        --title "Storage Pools" \
        --radiolist "Which storage pool for ${CONTENT_LABEL,,}?" \
        16 70 6 "${MENU[@]}" 3>&1 1>&2 2>&3)
    fi
  }
  
  # Select template storage
  msg_info "Selecting template storage"
  select_storage template
  TEMPLATE_STORAGE="$STORAGE_RESULT"
  msg_ok "Selected template storage: $TEMPLATE_STORAGE"
  
  # Select container storage
  msg_info "Selecting container storage"
  select_storage container
  CONTAINER_STORAGE="$STORAGE_RESULT"
  msg_ok "Selected container storage: $CONTAINER_STORAGE"
  
  # Copy template to selected storage if not already there
  if [ "$TEMPLATE_STORAGE" != "local" ]; then
    msg_info "Copying template to $TEMPLATE_STORAGE storage"
    if ! pveam download "$TEMPLATE_STORAGE" "$var_template" --source "/var/lib/vz/template/cache/$var_template" 2>/dev/null; then
      # If pveam doesn't work, try direct copy
      cp "/var/lib/vz/template/cache/$var_template" "$(pvesm path $TEMPLATE_STORAGE:vztmpl/$var_template)"
    fi
    msg_ok "Template copied to $TEMPLATE_STORAGE"
  fi
  
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
    --arch amd64 \
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
  
  # Get container IP with retry logic
  msg_info "Waiting for network configuration"
  for i in {1..10}; do
    sleep 2
    IP=$(pct exec "$CT_ID" -- ip -4 addr show eth0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
    if [ -n "$IP" ] && [ "$IP" != "127.0.0.1" ]; then
      msg_ok "Container IP: $IP"
      break
    fi
    if [ $i -eq 10 ]; then
      IP="DHCP"
      msg_warn "Could not determine IP address"
    fi
  done
  
  # Run post-install configuration
  msg_info "Running OpenWRT post-install configuration"
  pct exec "$CT_ID" -- bash -c "$(curl -fsSL ${BASE_URL}/install/openwrt-lxc-install.sh)"
  msg_ok "Post-install configuration completed"
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

# Call our custom container creation function
build_openwrt_containereation logic separate from main create_lxc.sh
# Ensure IP is set (it should be from build_openwrt_container)
if [ -z "$IP" ] || [ "$IP" = "DHCP" ]; then
  # Try one more time to get the IP
  IP=$(pct exec "$CT_ID" -- ip -4 addr show eth0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
  if [ -z "$IP" ]; then
    IP="<IP_ADDRESS>"
    IP_NOTE="\n${INFO}${YW} Run 'pct enter ${CT_ID}' then 'ip addr' to get the container's IP address${CL}"
  fi
fi

# Set CTID for final output
CTID="$CT_ID"

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access OpenWrt LuCI interface using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW} Default credentials: root / (no password)${CL}"
echo -e "${INFO}${YW} SSH Access: ssh root@${IP}${CL}"
echo -e "${INFO}${YW} Console Access: pct enter ${CTID}${CL}"
${IP_NOTE:-}