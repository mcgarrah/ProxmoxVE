# Debugging

How to debug the scripts being added to Proxmox Helper Scripts took some iterations. I'm not sure if these are the best way but it is what I sorted out.

## From inside the LXC

Debugging the script from inside the LXC requires setting a lot of variables and running from my development branch.

``` bash
pct enter 666
```

``` bash
apt install curl -y

# Set up ALL required environment variables for PowerDNS install
export FUNCTIONS_FILE_PATH="$(curl -fsSL https://raw.githubusercontent.com/mcgarrah/ProxmoxVE/feature/powerdns-lxc/misc/install.func)"
export CACHER=""
export CACHER_IP=""
export VERBOSE="yes"
export RECONFIGURE="yes"
export RANDOM_UUID="$(cat /proc/sys/kernel/random/uuid)"
export APPLICATION="PowerDNS"
export app="powerdns"
export SSH_ROOT="yes"
export SSH_AUTHORIZED_KEY=""
export PASSWORD="password"
export RETRY_NUM=5
export RETRY_EVERY=3
export DISABLEIPV6=""
export DIAGNOSTICS=""

# PowerDNS specific variables
export ROLE=b
export PRIVATE_ZONE="home.local"
export PUBLIC_ZONE="home.mcgarrah.org"
export PDNS_WEB_BIND="0.0.0.0"
export INSTALL_WEBUI="yes"

export RECURSOR_ALLOW="192.168.0.0/16"
export FORWARD_CHOICE="yes"
export FORWARD_DOMAIN="home.local"
export FORWARD_IP=""

# Now run the install script
curl -fsSL https://raw.githubusercontent.com/mcgarrah/ProxmoxVE/feature/powerdns-lxc/install/powerdns-install.sh | bash
```

## From Proxmox node

This also requires changes to the `build.func` to support using the `var_install_url` or it defaults to non-dev branch ones.

```bash
root@tanaka:/mnt/pve/cephfs/github/mcgarrah/ProxmoxVE# git pull
remote: Enumerating objects: 61, done.
remote: Counting objects: 100% (57/57), done.
remote: Compressing objects: 100% (29/29), done.
remote: Total 61 (delta 39), reused 46 (delta 28), pack-reused 4 (from 1)
Unpacking objects: 100% (61/61), 40.24 KiB | 235.00 KiB/s, done.
From https://github.com/mcgarrah/ProxmoxVE
   7abcc0bb9..7aa7404d5  feature/powerdns-lxc -> origin/feature/powerdns-lxc
Updating 7abcc0bb9..7aa7404d5
Fast-forward
 ct/powerdns.sh                     |  35 ++++++++++----
 frontend/public/json/powerdns.json |  30 +++++++++++-
 install/powerdns-install.sh        | 193 ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++----------------
 test_powerdns.sh                   |  19 ++++++++
 4 files changed, 228 insertions(+), 49 deletions(-)
 create mode 100644 test_powerdns.sh
root@tanaka:/mnt/pve/cephfs/github/mcgarrah/ProxmoxVE# var_install_url="https://raw.githubusercontent.com/mcgarrah/ProxmoxVE/feature/powerdns-lxc/install" var_ctid=666 var_hostname=pdns bash ct/powerdns.sh
```

```bash
git pull
var_install_url="https://raw.githubusercontent.com/mcgarrah/ProxmoxVE/feature/powerdns-lxc" bash ct/powerdns.sh
```

## Create login screen text

Text to ASCII Art Generator: Create ASCII Art from Text

[https://patorjk.com/software/taag/](https://patorjk.com/software/taag/#p=display&f=Slant&t=PowerDNS&x=none&v=4&h=4&w=80&we=false)
