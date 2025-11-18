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
  echo "Debug: Entering create_openwrt_template function" >&2
  
  # Get latest OpenWRT version (24.x or newer)
  local openwrt_version=$(curl -s https://downloads.openwrt.org/releases/ | \
    grep -oE 'href="[0-9]+\.[0-9]+\.[0-9]+/"' | \
    sed 's/href="//;s/\/"//' | \
    sort -V | \
    awk -F. '$1 >= 24 {print}' | \
    tail -1)
  
  if [ -z "$openwrt_version" ]; then
    echo "Debug: Failed to fetch latest version, using fallback" >&2
    openwrt_version="24.10.4"
  fi
  
  local template_name="openwrt-${openwrt_version}-lxc_amd64.tar.gz"
  local template_path="/var/lib/vz/template/cache/$template_name"
  
  echo "Debug: Using OpenWRT version: $openwrt_version" >&2
  
  echo "Debug: Checking if template exists at: $template_path" >&2
  if [ ! -f "$template_path" ]; then
    echo "Debug: Template not found, creating it" >&2
    echo "Debug: BASE_URL is: $BASE_URL" >&2
    
    # Test if we can reach the template creation script
    echo "Debug: Testing curl access to template script" >&2
    if ! curl -fsSL --connect-timeout 10 "${BASE_URL}/misc/create-openwrt-template.sh" >/dev/null; then
      echo "Error: Cannot access template creation script at ${BASE_URL}/misc/create-openwrt-template.sh" >&2
      exit 1
    fi
    echo "Debug: Template script is accessible" >&2
    
    echo "Debug: Starting template creation with timeout" >&2
    # Use timeout to prevent hanging
    if ! timeout 300 bash <(curl -fsSL ${BASE_URL}/misc/create-openwrt-template.sh); then
      echo "Error: Failed to create OpenWRT template (timeout or error)" >&2
      exit 1
    fi
    echo "Debug: Template creation script completed" >&2
    
    # Verify template was created successfully
    if [ ! -f "$template_path" ]; then
      echo "Error: Template creation completed but file not found at $template_path" >&2
      exit 1
    fi
    
    # Verify template is not empty
    if [ ! -s "$template_path" ]; then
      echo "Error: Template file is empty: $template_path" >&2
      exit 1
    fi
    
    echo "Debug: Template created successfully" >&2
  else
    echo "Debug: Using existing template: $template_name" >&2
  fi
  
  echo "Debug: Exiting create_openwrt_template function" >&2
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

# Override container variables after base_settings - OpenWRT MUST be privileged
CT_TYPE="0"  # Hardcoded: OpenWRT native requires privileged container
CT_ID=${CT_ID:-$(pvesh get /cluster/nextid)}
# Force hostname to openwrt-lxc (NSAPP would be just "openwrt")
HN="openwrt-lxc"
TAGS="community-script;${var_tags}"

function default_settings() {
  CT_TYPE="0"
  PW=""
  CT_ID=$NEXTID
  HN="openwrt-lxc"  # Force to openwrt-lxc instead of NSAPP (which is just "openwrt")
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

# Custom build_container function for OpenWRT (unmanaged OS type requires direct pct create)
build_container() {
  # Debug: Show all relevant variables
  echo "Debug: build_container called with:" >&2
  echo "Debug: CTID='$CTID'" >&2
  echo "Debug: CT_ID='$CT_ID'" >&2
  echo "Debug: NEXTID='$NEXTID'" >&2
  
  # The build system should set CTID from user input
  if [ -z "$CTID" ]; then
    # Fallback: try to use CT_ID or NEXTID
    if [ -n "$CT_ID" ]; then
      CTID="$CT_ID"
      echo "Debug: Using CT_ID as fallback: $CTID" >&2
    elif [ -n "$NEXTID" ]; then
      CTID="$NEXTID"
      echo "Debug: Using NEXTID as fallback: $CTID" >&2
    else
      msg_error "No container ID available (CTID, CT_ID, NEXTID all empty)"
      exit 1
    fi
  fi
  
  msg_info "Building container with ID: $CTID"
  
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
    # Check if template already exists in target storage
    if ! pvesm list "$TEMPLATE_STORAGE" --content vztmpl | grep -q "$var_template"; then
      if ! pveam download "$TEMPLATE_STORAGE" "$var_template" --source "/var/lib/vz/template/cache/$var_template" 2>/dev/null; then
        # If pveam doesn't work, try direct copy
        local target_path=$(pvesm path "$TEMPLATE_STORAGE:vztmpl/$var_template" 2>/dev/null)
        if [ -n "$target_path" ]; then
          cp "/var/lib/vz/template/cache/$var_template" "$target_path"
        else
          msg_error "Cannot determine target path for template"
          exit 1
        fi
      fi
    fi
    msg_ok "Template available in $TEMPLATE_STORAGE"
  fi
  
  msg_info "Creating OpenWRT LXC Container"
  
  # Build network string from build system variables
  NET_STRING="name=eth0,bridge=$BRG,ip=$NET"
  if [ -n "$GATE" ]; then
    NET_STRING="$NET_STRING$GATE"
  fi
  if [ -n "$MAC" ]; then
    NET_STRING="$NET_STRING$MAC"
  fi
  if [ -n "$VLAN" ]; then
    NET_STRING="$NET_STRING$VLAN"
  fi
  if [ -n "$MTU" ]; then
    NET_STRING="$NET_STRING$MTU"
  fi
  
  # Create container directly with pct (required for unmanaged OS type)
  # OpenWRT native MUST be privileged (--unprivileged 0) and unmanaged
  if ! pct create "$CTID" "$TEMPLATE_STORAGE:vztmpl/$var_template" \
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
  
  msg_ok "Created LXC Container $CTID"
  
  # Start container
  msg_info "Starting LXC Container"
  pct start "$CTID"
  msg_ok "Started LXC Container"
  
  # Get container IP with retry logic
  msg_info "Waiting for network configuration"
  echo "Debug: About to start IP detection loop with CTID='$CTID'" >&2
  
  # Verify container exists and is running
  if ! pct status "$CTID" >/dev/null 2>&1; then
    msg_error "Container $CTID does not exist or is not accessible"
    exit 1
  fi
  
  for i in {1..10}; do
    sleep 2
    echo "Debug: IP detection attempt $i/10 for container $CTID" >&2
    IP=$(pct exec "$CTID" -- ip -4 addr show eth0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
    if [ -n "$IP" ] && [ "$IP" != "127.0.0.1" ]; then
      msg_ok "Container IP: $IP"
      break
    fi
    if [ $i -eq 10 ]; then
      IP="DHCP"
      msg_warn "Could not determine IP address"
    fi
  done
  
  # Run OpenWRT-specific post-install
  msg_info "Running OpenWRT post-install configuration"
  pct exec "$CTID" -- ash -c "$(curl -fsSL ${BASE_URL}/install/openwrt-lxc-install.sh)"
  msg_ok "Post-install configuration completed"
  
  # Call description function after container is fully set up
  description
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

# Use standard build system - start() will call build_container() automatically
start
# Note: description() is called automatically by build.func after container creation

# Ensure IP is set with fallback logic
if [ -z "$IP" ] || [ "$IP" = "DHCP" ]; then
  # Try one more time to get the IP
  IP=$(pct exec "$CTID" -- ip -4 addr show eth0 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
  if [ -z "$IP" ]; then
    IP="<IP_ADDRESS>"
    IP_NOTE="\n${INFO}${YW} Run 'pct enter ${CTID}' then 'ip addr' to get the container's IP address${CL}"
  fi
fi

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access OpenWrt LuCI interface using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
echo -e "${INFO}${YW} Default credentials: root / (no password)${CL}"
echo -e "${INFO}${YW} SSH Access: ssh root@${IP}${CL}"
echo -e "${INFO}${YW} Console Access: pct enter ${CTID}${CL}"
${IP_NOTE:-}
