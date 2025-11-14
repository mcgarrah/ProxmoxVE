#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2025 community-scripts ORG
# Author: Michael McGarrah (mcgarrah)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.powerdns.com/

APP="PowerDNS"
# shellcheck disable=SC2034
var_install="${var_install:-powerdns-install}"
# shellcheck disable=SC2034
var_tags="${var_tags:-dns;powerdns}"
var_ctid="${var_ctid:-}"
var_hostname="${var_hostname:-powerdns}"
# Increase CPU and RAM if PowerDNS-Admin is requested
if [[ "${INSTALL_WEBUI,,}" =~ ^(y|yes)$ ]]; then
  var_cpu="${var_cpu:-2}"
  var_ram="${var_ram:-1024}"
else
  var_cpu="${var_cpu:-1}"
  var_ram="${var_ram:-512}"
fi
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_password="${var_password:-}"
var_bridge="${var_bridge:-}"
var_ip="${var_ip:-}"
var_gw="${var_gw:-}"
var_vlan="${var_vlan:-}"
var_unprivileged="${var_unprivileged:-0}"
# Disable VAAPI prompts (not relevant for PowerDNS)
NO_VAAPI="1"
# Set install URL if provided
var_install_url="${var_install_url:-}"

# PowerDNS specific configuration
ROLE="${ROLE:-}"  # Allow interactive prompt
PRIVATE_ZONE="${PRIVATE_ZONE:-home.local}"  # Default private zone
PUBLIC_ZONE="${PUBLIC_ZONE:-}"  # No default public zone
PDNS_WEB_BIND="${PDNS_WEB_BIND:-127.0.0.1}"  # Default to localhost only
RECURSOR_ALLOW="${RECURSOR_ALLOW:-192.168.0.0/16}"  # Default LAN access
FORWARD_CHOICE="${FORWARD_CHOICE:-}"  # No forwarding by default
FORWARD_DOMAIN="${FORWARD_DOMAIN:-}"
FORWARD_IP="${FORWARD_IP:-}"
INSTALL_WEBUI="${INSTALL_WEBUI:-}"  # Optional PowerDNS-Admin web interface

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if ! pct exec "$CTID" -- systemctl --quiet is-enabled pdns.service && ! pct exec "$CTID" -- systemctl --quiet is-enabled pdns-recursor.service; then
    msg_error "No ${APP} installation found in container ${CTID}!"
    exit
  fi
  msg_warn "Please update PowerDNS components inside the LXC using apt (e.g. apt-get update && apt-get upgrade)."
  exit
}

export var_tags
export var_ctid
export var_hostname
export var_cpu
export var_ram
export var_disk
export var_password
export var_bridge
export var_ip
export var_gw
export var_vlan
export var_unprivileged
export var_install_url
export NO_VAAPI

# Export PowerDNS configuration
export ROLE
export PRIVATE_ZONE
export PUBLIC_ZONE
export PDNS_WEB_BIND
export RECURSOR_ALLOW
export FORWARD_CHOICE
export FORWARD_DOMAIN
export FORWARD_IP
export INSTALL_WEBUI

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been initialized.\n${CL}"
echo -e "${INFO}${YW}Notes:${CL}"
echo -e "${TAB}This LXC installs PowerDNS. Use the console or ssh into the container to manage zones and configuration."
echo -e "${TAB}For authoritative installs: use pdnsutil to create and manage zones."
echo -e "${TAB}For recursor installs: edit /etc/powerdns/recursor.conf to tune ACLs and forward zones."
