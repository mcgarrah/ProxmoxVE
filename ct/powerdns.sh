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
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_password="${var_password:-}"
var_bridge="${var_bridge:-}"
var_ip="${var_ip:-}"
var_gw="${var_gw:-}"
var_vlan="${var_vlan:-}"
var_unprivileged="${var_unprivileged:-0}"

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

start
build_container
description
export var_install_url
export ROLE
export PDNS_WEB_BIND
export RECURSOR_ALLOW
export PRIVATE_ZONE
export PUBLIC_ZONE
export FORWARD_CHOICE
export FORWARD_DOMAIN
export FORWARD_IP

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been initialized.\n${CL}"
echo -e "${INFO}${YW}Notes:${CL}"
echo -e "${TAB}This LXC installs PowerDNS. Use the console or ssh into the container to manage zones and configuration."
echo -e "${TAB}For authoritative installs: use pdnsutil to create and manage zones."
echo -e "${TAB}For recursor installs: edit /etc/powerdns/recursor.conf to tune ACLs and forward zones."
