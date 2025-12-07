#!/bin/bash

# Test script to verify PowerDNS installation with environment variables
export var_install_url="https://raw.githubusercontent.com/mcgarrah/ProxmoxVE/feature/powerdns-lxc/install"
export var_ctid=666
export var_hostname=pdns
export ROLE=a
export PRIVATE_ZONE=""
export PUBLIC_ZONE=""
export PDNS_WEB_BIND="127.0.0.1"

echo "Testing PowerDNS installation with:"
echo "  Container ID: $var_ctid"
echo "  Hostname: $var_hostname"
echo "  Role: $ROLE"
echo "  NO_VAAPI should prevent VAAPI prompts"

# Run the script
bash ct/powerdns.sh