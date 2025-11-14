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

# Ask about PowerDNS-Admin web interface for authoritative installations
if [[ "$ROLE" == "a" || "$ROLE" == "b" ]] && [[ -z "$INSTALL_WEBUI" ]]; then
  read -r -p "Install PowerDNS-Admin web interface? [y/N] " INSTALL_WEBUI
  
  # If web interface is chosen, ask about API bind address
  if [[ "${INSTALL_WEBUI,,}" =~ ^(y|yes)$ ]] && [[ -z "$PDNS_WEB_BIND" ]]; then
    read -r -p "Bind PowerDNS API to all interfaces (0.0.0.0) or localhost only (127.0.0.1)? [0.0.0.0/127.0.0.1] " PDNS_WEB_BIND
    PDNS_WEB_BIND=${PDNS_WEB_BIND:-0.0.0.0}
  fi
fi

# Ask about zone creation for authoritative installations
if [[ "$ROLE" == "a" || "$ROLE" == "b" ]] && [[ -z "$PRIVATE_ZONE" ]]; then
  read -r -p "Create private zone? Enter zone name or press Enter to skip [home.local] " PRIVATE_ZONE
  PRIVATE_ZONE=${PRIVATE_ZONE:-home.local}
fi

if [[ "$ROLE" == "a" || "$ROLE" == "b" ]] && [[ -z "$PUBLIC_ZONE" ]]; then
  read -r -p "Create public zone? Enter zone name or press Enter to skip [] " PUBLIC_ZONE
fi

# Ask about recursor configuration
if [[ "$ROLE" == "r" || "$ROLE" == "b" ]] && [[ -z "$RECURSOR_ALLOW" ]]; then
  read -r -p "Enter allowed networks for recursor queries [192.168.0.0/16] " RECURSOR_ALLOW
  RECURSOR_ALLOW=${RECURSOR_ALLOW:-192.168.0.0/16}
fi

if [[ "$ROLE" == "r" || "$ROLE" == "b" ]] && [[ -z "$FORWARD_CHOICE" ]]; then
  read -r -p "Configure zone forwarding to authoritative server? [y/N] " FORWARD_CHOICE
  if [[ "${FORWARD_CHOICE,,}" =~ ^(y|yes)$ ]]; then
    if [[ -z "$FORWARD_DOMAIN" ]]; then
      read -r -p "Enter domain to forward (e.g., home.local): " FORWARD_DOMAIN
    fi
    if [[ -z "$FORWARD_IP" ]]; then
      read -r -p "Enter IP address to forward to (e.g., 192.168.1.10): " FORWARD_IP
    fi
  fi
fi

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

  # Generate secure API key and store it
  PDNS_API_KEY=$(openssl rand -hex 32)
  
  cat <<EOF >/etc/powerdns/pdns.conf
launch=gsqlite3
gsqlite3-database=/var/lib/powerdns/pdns.sqlite3
# Enable the API so pdnsutil can manage zones
api=yes
api-key=${PDNS_API_KEY}
# Webserver; bind address default is local-only for safety
webserver=yes
webserver-address=${PDNS_WEB_BIND}
webserver-port=8081
EOF
  
  # Secure the config file
  chmod 640 /etc/powerdns/pdns.conf
  chown root:pdns /etc/powerdns/pdns.conf

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

  # Basic recursor config - use different port if authoritative is also installed
  if [[ "$ROLE" == "b" ]]; then
    RECURSOR_PORT=5353
    msg_info "Both authoritative and recursor selected - configuring recursor on port 5353"
  else
    RECURSOR_PORT=53
  fi
  
  cat <<EOF >"${RECURSOR_CONF}"
# Basic PowerDNS recursor config
local-address=0.0.0.0
local-port=${RECURSOR_PORT}
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
    if [[ "$ROLE" == "b" ]]; then
      msg_ok "PowerDNS recursor installed and running on port 5353"
      msg_info "Authoritative server on port 53, Recursor on port 5353"
    else
      msg_ok "PowerDNS recursor installed and running on port 53"
    fi
  else
    msg_error "PowerDNS recursor did not start correctly; see journalctl -u pdns-recursor -n 50"
    journalctl -u pdns-recursor -n 50 --no-pager || true
  fi
fi

# Optional PowerDNS-Admin web interface installation
if [[ "${INSTALL_WEBUI,,}" =~ ^(y|yes)$ ]] && [[ "$ROLE" == "a" || "$ROLE" == "b" ]]; then
  msg_info "Installing PowerDNS-Admin web interface"
  
  # Install system dependencies (SQLite-only, no MariaDB/PostgreSQL)
  $STD apt-get update
  $STD apt-get install -y sudo python3 python3-pip python3-venv git build-essential pkg-config
  $STD apt-get install -y libffi-dev libxml2-dev libldap2-dev libsasl2-dev libssl-dev libxmlsec1-dev
  $STD apt-get install -y nodejs npm
  
  # Create powerdns-admin user
  useradd --system --home /opt/powerdns-admin --shell /bin/bash powerdns-admin || true
  
  # Clone PowerDNS-Admin from the local repository
  if [[ ! -d /opt/powerdns-admin ]]; then
    git clone https://github.com/PowerDNS-Admin/PowerDNS-Admin.git /opt/powerdns-admin
    chown -R powerdns-admin:powerdns-admin /opt/powerdns-admin
  fi
  
  # Setup Python virtual environment
  cd /opt/powerdns-admin
  sudo -u powerdns-admin python3 -m venv venv
  sudo -u powerdns-admin ./venv/bin/pip install --upgrade pip
  
  # Remove MySQL/PostgreSQL packages from requirements.txt for SQLite-only installation
  sed -i '/^mysqlclient==/d' requirements.txt
  sed -i '/^psycopg2==/d' requirements.txt
  
  # Install Python dependencies (SQLite-only)
  sudo -u powerdns-admin ./venv/bin/pip install --use-pep517 -r requirements.txt
  
  # Install frontend dependencies manually to ensure they exist
  cd /opt/powerdns-admin/powerdnsadmin/static
  
  # Copy the correct package.json from the repository root to static directory
  sudo -u powerdns-admin cp /opt/powerdns-admin/package.json /opt/powerdns-admin/powerdnsadmin/static/package.json
  
  # Install npm packages
  sudo -u powerdns-admin npm install
  
  # Verify critical files exist after npm install
  if [[ ! -f "node_modules/@fortawesome/fontawesome-free/css/all.css" ]]; then
    msg_warn "FontAwesome CSS not found after npm install"
  fi
  
  # Modify assets.py to remove cssrewrite (as done in Dockerfile)
  sed -i -r -e "s|'rcssmin',\s?'cssrewrite'|'rcssmin'|g" /opt/powerdns-admin/powerdnsadmin/assets.py
  
  # Build Flask assets
  cd /opt/powerdns-admin
  sudo -u powerdns-admin FLASK_APP=powerdnsadmin ./venv/bin/flask assets build || msg_warn "Asset build failed, but continuing with installation"
  
  # Generate secure Flask secret key
  FLASK_SECRET_KEY=$(openssl rand -hex 32)
  
  # Create custom config for our installation
  cat <<EOF >/opt/powerdns-admin/configs/local_config.py
# Local PowerDNS-Admin configuration
SECRET_KEY = '${FLASK_SECRET_KEY}'
BIND_ADDRESS = '0.0.0.0'
PORT = 9191

# Database - SQLite
SQLALCHEMY_DATABASE_URI = 'sqlite:////opt/powerdns-admin/powerdns-admin.db'
SQLALCHEMY_TRACK_MODIFICATIONS = False

# PowerDNS API settings
PDNS_STATS_URL = 'http://127.0.0.1:8081'
PDNS_API_URL = 'http://127.0.0.1:8081'
PDNS_API_KEY = '${PDNS_API_KEY}'
PDNS_VERSION = '4.7.0'

# Basic settings
BASIC_ENABLED = True
SIGNUP_ENABLED = False
EOF
  
  # Secure the config file
  chmod 640 /opt/powerdns-admin/configs/local_config.py
  
  chown powerdns-admin:powerdns-admin /opt/powerdns-admin/configs/local_config.py
  
  # Initialize database
  sudo -u powerdns-admin mkdir -p /opt/powerdns-admin/instance
  sudo -u powerdns-admin touch /opt/powerdns-admin/powerdns-admin.db
  
  # Initialize Flask database migrations
  cd /opt/powerdns-admin
  sudo -u powerdns-admin FLASK_APP=powerdnsadmin ./venv/bin/flask db upgrade || true
  
  # Create default admin user (admin/admin)
  sudo -u powerdns-admin FLASK_APP=powerdnsadmin ./venv/bin/flask user create-user --username admin --email admin@example.com --firstname Admin --lastname User --password admin --admin || msg_warn "Admin user creation failed or user already exists"
  
  # Configure PowerDNS server connection automatically
  sudo -u powerdns-admin FLASK_APP=powerdnsadmin ./venv/bin/python3 -c "
import sys
sys.path.insert(0, '/opt/powerdns-admin')
from powerdnsadmin import create_app
from powerdnsadmin.models.server import Server
from powerdnsadmin.models.setting import Setting

app = create_app()
with app.app_context():
    # Check if server already exists
    existing_server = Server.query.filter_by(name='localhost').first()
    if not existing_server:
        # Create PowerDNS server entry
        server = Server(
            name='localhost',
            host='127.0.0.1',
            port=8081,
            version='4.7.0',
            api_key='${PDNS_API_KEY}'
        )
        server.create()
        print('PowerDNS server configured successfully')
    else:
        print('PowerDNS server already configured')
" || msg_warn "PowerDNS server configuration failed"
  
  # Use the existing run.py from the repository
  # Create wrapper script to load custom config
  cat <<EOF >/opt/powerdns-admin/start.py
#!/usr/bin/env python3
import os
import sys
sys.path.insert(0, '/opt/powerdns-admin')

# Set config file path
os.environ['POWERDNS_ADMIN_CONFIG'] = '/opt/powerdns-admin/configs/local_config.py'

from powerdnsadmin import create_app

if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=9191, debug=False)
else:
    app = create_app()
EOF
  
  chown powerdns-admin:powerdns-admin /opt/powerdns-admin/start.py
  chmod +x /opt/powerdns-admin/start.py
  
  # Create systemd service
  cat <<EOF >/etc/systemd/system/powerdns-admin.service
[Unit]
Description=PowerDNS-Admin Web Interface
Requires=pdns.service
After=pdns.service

[Service]
User=powerdns-admin
Group=powerdns-admin
WorkingDirectory=/opt/powerdns-admin
Environment=POWERDNS_ADMIN_CONFIG=/opt/powerdns-admin/configs/local_config.py
ExecStart=/opt/powerdns-admin/venv/bin/gunicorn --bind 0.0.0.0:9191 --workers 2 start:app
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
  
  # Enable and start service
  systemctl daemon-reload
  systemctl enable --now powerdns-admin
  
  if systemctl --quiet is-active powerdns-admin; then
    msg_ok "PowerDNS-Admin installed and running on port 9191"
    msg_info "Access PowerDNS-Admin at: http://$(hostname -I | awk '{print $1}'):9191"
    msg_info "Default login: admin / admin (change after first login)"
  else
    msg_error "PowerDNS-Admin failed to start; see journalctl -u powerdns-admin"
  fi
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

echo -e "\n${INFO}PowerDNS installation complete.\n"

# Display services based on role
if [[ "$ROLE" == "a" || "$ROLE" == "b" ]]; then
  echo -e "${TAB}Authoritative server running on port 53"
fi
if [[ "$ROLE" == "r" ]]; then
  echo -e "${TAB}Recursor running on port 53"
elif [[ "$ROLE" == "b" ]]; then
  echo -e "${TAB}Recursor running on port 5353"
fi

# Display API information for authoritative installations
if [[ "$ROLE" == "a" || "$ROLE" == "b" ]]; then
  echo -e "${TAB}PowerDNS API URL: http://127.0.0.1:8081/"
  echo -e "${TAB}PowerDNS API Key: ${PDNS_API_KEY}"
  echo -e "${TAB}PowerDNS Version: 4.7.0"
fi

# Display usage instructions
if [[ "$ROLE" == "a" || "$ROLE" == "b" ]]; then
  echo -e "${TAB}Use pdnsutil to add zones and records (pdnsutil help)"
fi
if [[ "$ROLE" == "r" || "$ROLE" == "b" ]]; then
  echo -e "${TAB}Edit /etc/powerdns/recursor.conf to adjust ACLs and forward-zones as needed"
fi

# Display Proxmox SDN integration info for authoritative installations
if [[ "$ROLE" == "a" || "$ROLE" == "b" ]]; then
  echo -e "\n${INFO}For Proxmox SDN integration:"
  echo -e "${TAB}ID: powerdns"
  echo -e "${TAB}API Key: ${PDNS_API_KEY}"
  echo -e "${TAB}URL: http://$(hostname -I | awk '{print $1}'):8081/"
  echo -e "${TAB}TTL: 300"
fi
