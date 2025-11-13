#!/usr/bin/env bash

# Copyright (c) 2025 community-scripts ORG
# Author: Michael McGarrah (mcgarrah)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.powerdns.com/
# shellcheck disable=SC1091,SC1090
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "PowerDNS installer - choose role"
# Allow non-interactive mode via environment variables. ROLE may be set to a/r/b or authoritative/recursor/both
ROLE=${ROLE:-}
if [[ -z "$ROLE" ]]; then
  read -r -p "Install PowerDNS as (a)uthoritative, (r)ecursor, or (b)oth? [a/r/b] " ROLE
fi
ROLE=${ROLE,,}
case "$ROLE" in
  authoritative) ROLE=a ;;
  recursor) ROLE=r ;;
  both) ROLE=b ;;
  a|r|b) ;;
  *) ROLE="a" ;;
esac

if [[ "$ROLE" == "a" || "$ROLE" == "b" ]]; then
  msg_info "PowerDNS Authoritative: preflight checks"
  SKIP_PDNS_INSTALL=0
  if dpkg -s pdns-server >/dev/null 2>&1; then
    msg_warn "pdns-server package already installed."
    if [[ "${RECONFIGURE,,}" != "yes" ]]; then
      msg_warn "To re-run configuration set RECONFIGURE=yes in the environment. Skipping installation steps."
      SKIP_PDNS_INSTALL=1
    else
      msg_info "RECONFIGURE=yes set; continuing reconfiguration."
    fi
  fi

  if [[ $SKIP_PDNS_INSTALL -eq 0 ]]; then
    msg_info "Installing PowerDNS Authoritative Server (sqlite backend)"
    $STD apt-get update
    $STD apt-get install -y pdns-server pdns-backend-sqlite3 sqlite3
  else
    msg_info "Skipping apt install for pdns-server (already present)"
    # Ensure sqlite3 is installed even if pdns is already present
    apt-get update >/dev/null
    apt-get install -y sqlite3
  fi

  # Configure sqlite backend
  msg_info "Configuring /etc/powerdns/pdns.conf for sqlite backend"
  mkdir -p /var/lib/powerdns
  chown -R pdns:pdns /var/lib/powerdns || true

  # Allow binding webserver to chosen address via PDNS_WEB_BIND env var (default local-only)
  PDNS_WEB_BIND=${PDNS_WEB_BIND:-127.0.0.1}
  if [[ "$PDNS_WEB_BIND" == "0.0.0.0" ]]; then
    msg_warn "You chose to bind the PowerDNS webserver to 0.0.0.0 — ensure this is intentional and secure."
  fi

  cat <<EOF >/etc/powerdns/pdns.conf
launch=gsqlite3
gsqlite3-database=/var/lib/powerdns/pdns.sqlite3
# Enable the API so pdnsutil can manage zones
api=yes
api-key=$(openssl rand -hex 16)
# Webserver; bind address default is local-only for safety
webserver=yes
webserver-address=${PDNS_WEB_BIND}
webserver-port=8081
EOF

  # Initialize the SQLite database
  msg_info "Initializing SQLite database"
  if [[ ! -f /var/lib/powerdns/pdns.sqlite3 ]]; then
    sqlite3 /var/lib/powerdns/pdns.sqlite3 < /usr/share/doc/pdns-backend-sqlite3/schema.sqlite3.sql
    chown pdns:pdns /var/lib/powerdns/pdns.sqlite3
  fi

  msg_info "Enabling and starting pdns"
  systemctl enable --now pdns
  # Verify service started
  if systemctl --quiet is-active pdns; then
    msg_ok "PowerDNS authoritative installed and running"
  else
    msg_error "PowerDNS authoritative did not start correctly; see journalctl -u pdns -n 50"
    journalctl -u pdns -n 50 --no-pager || true
  fi

  # Optional sample zones (honor env vars PRIVATE_ZONE and PUBLIC_ZONE for non-interactive)
  if [[ -n "$PRIVATE_ZONE" ]]; then
    if command -v pdnsutil >/dev/null 2>&1; then
      msg_info "Creating private zone $PRIVATE_ZONE"
      pdnsutil create-zone "$PRIVATE_ZONE" "ns1.$PRIVATE_ZONE" || msg_warn "pdnsutil create-zone returned non-zero"
      msg_ok "Created zone $PRIVATE_ZONE"
    else
      msg_warn "pdnsutil not found; skipping zone creation. You can use pdnsutil inside the container later."
    fi
  fi

  if [[ -n "$PUBLIC_ZONE" ]]; then
    if command -v pdnsutil >/dev/null 2>&1; then
      msg_info "Creating public zone $PUBLIC_ZONE"
      pdnsutil create-zone "$PUBLIC_ZONE" "ns1.$PUBLIC_ZONE" || msg_warn "pdnsutil create-zone returned non-zero"
      msg_ok "Created zone $PUBLIC_ZONE"
    else
      msg_warn "pdnsutil not found; skipping zone creation. You can use pdnsutil inside the container later."
    fi
  fi
fi

if [[ "$ROLE" == "r" || "$ROLE" == "b" ]]; then
  msg_info "PowerDNS Recursor: preflight checks"
  SKIP_RECURSOR_INSTALL=0
  if dpkg -s pdns-recursor >/dev/null 2>&1; then
    msg_warn "pdns-recursor package already installed."
    if [[ "${RECONFIGURE,,}" != "yes" ]]; then
      msg_warn "To re-run configuration set RECONFIGURE=yes in the environment. Skipping installation steps."
      SKIP_RECURSOR_INSTALL=1
    else
      msg_info "RECONFIGURE=yes set; continuing reconfiguration."
    fi
  fi

  if [[ $SKIP_RECURSOR_INSTALL -eq 0 ]]; then
    msg_info "Installing PowerDNS Recursor"
    $STD apt-get update
    $STD apt-get install -y pdns-recursor
  else
    msg_info "Skipping apt install for pdns-recursor (already present)"
  fi

  RECURSOR_CONF="/etc/powerdns/recursor.conf"
  msg_info "Configuring recursor to listen and allow client networks"

  # Default allow-from as common LAN RFC1918 block; allow env var RECURSOR_ALLOW to prefill
  RECURSOR_ALLOW=${RECURSOR_ALLOW:-192.168.0.0/16}

  # Basic recursor config
    cat <<EOF >"${RECURSOR_CONF}"
# Basic PowerDNS recursor config
local-address=0.0.0.0
allow-from=${RECURSOR_ALLOW}
# Uncomment and set forward-zones if you want the recursor to forward specific zones
# forward-zones=example.local=192.0.2.10
EOF

  # Optionally forward a private zone to an authoritative server — honor env vars FORWARD_CHOICE, FORWARD_DOMAIN, FORWARD_IP
  if [[ "${FORWARD_CHOICE,,}" =~ ^(y|yes)$ ]] && [[ -n "$FORWARD_DOMAIN" && -n "$FORWARD_IP" ]]; then
    # Append forward-zones entry
    if grep -q "^forward-zones" "${RECURSOR_CONF}"; then
        sed -i "/^forward-zones/s/$/,${FORWARD_DOMAIN}=${FORWARD_IP}/" "${RECURSOR_CONF}" || true
      else
        echo "forward-zones=${FORWARD_DOMAIN}=${FORWARD_IP}" >>"${RECURSOR_CONF}"
      fi
    msg_ok "Configured recursor to forward ${FORWARD_DOMAIN} to ${FORWARD_IP}"
  fi

  msg_info "Enabling and starting pdns-recursor"
  systemctl enable --now pdns-recursor
  if systemctl --quiet is-active pdns-recursor; then
    msg_ok "PowerDNS recursor installed and running"
  else
    msg_error "PowerDNS recursor did not start correctly; see journalctl -u pdns-recursor -n 50"
    journalctl -u pdns-recursor -n 50 --no-pager || true
  fi
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

echo -e "\n${INFO}PowerDNS installation complete.\n"
echo -e "${TAB}If you installed authoritative: use pdnsutil to add zones and records (pdnsutil help)."
echo -e "${TAB}If you installed recursor: edit /etc/powerdns/recursor.conf to adjust ACLs and forward-zones as needed."
