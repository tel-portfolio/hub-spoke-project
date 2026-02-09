#!/bin/bash

# Stop script on any error
set -e

# --- 1. CLOUD-INIT COMPATIBILITY FIX ---
# Cloud-init runs as root, so $SUDO_USER is empty. 
# We assume the first user with ID 1000 is your admin user (standard for Ubuntu).
PRIMARY_USER=$(getent passwd "1000" | cut -d: -f1)
USER_HOME=$(getent passwd "$PRIMARY_USER" | cut -d: -f6)

if [ -z "$PRIMARY_USER" ]; then
    echo "Error: Could not detect primary user. Hardcode the username if needed."
    exit 1
fi

echo "-- Configuration started for NVA User: $PRIMARY_USER --"

# Change timezone
timedatectl set-timezone America/New_York

# Update system and install utilities
echo "-- Installing Utilities --"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nano unattended-upgrades ufw ca-certificates curl gnupg lsb-release

# --- 2. NVA CORE: IP FORWARDING ---
# Required to pass traffic from LAN to WAN
echo "-- Enabling IP Forwarding --"
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p

# --- 3. NVA CORE: UFW ROUTING CONFIG ---
# By default, UFW drops forwarded packets. We must allow them.
echo "-- Configuring UFW for Routing --"
sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw

# --- 4. NVA CORE: NAT (The "Secret Sauce") ---
# We need to add a POSTROUTING rule to UFW's "before.rules" file.
# This mimics the "Masquerade" logic we discussed.
# Assuming eth0 is WAN and your Spoke VNETs are in 10.0.0.0/8
cat <<EOT >> /etc/ufw/before.rules

# NAT Table Rules
*nat
:POSTROUTING ACCEPT [0:0]
# Forward traffic from Internal Network (10.0.0.0/8) through eth0 (WAN)
-A POSTROUTING -s 10.0.0.0/8 -o eth0 -j MASQUERADE
COMMIT
EOT

# --- 5. FIREWALL RULES ---
echo "-- Applying Firewall Rules --"
ufw allow ssh
# Allow traffic from internal LAN (LAN Interface is likely eth1)
ufw allow in on eth1 to any port 22
ufw allow in on eth1 to any port 80
ufw allow in on eth1 to any port 443
# Or allow ALL traffic from your internal network (Simpler for Dev)
ufw allow from 10.0.0.0/8

# Enable UFW without prompt
echo "y" | ufw enable

# --- 6. SSH HARDENING (Your existing logic) ---
echo "-- Hardening SSH --"
SSHD_CONFIG="/etc/ssh/sshd_config"
cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak.$(date +%F_%T)"

# Only apply these if the file exists (Safety)
if [ -f "$SSHD_CONFIG" ]; then
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
    sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' "$SSHD_CONFIG"
    sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSHD_CONFIG"
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"
    
    # Terraform handles the "authorized_keys" injection automatically via the 
    # "admin_ssh_key" block in main.tf, so we don't need to manually touch .ssh/authorized_keys here.
fi

systemctl restart ssh

echo "-- NVA Bootstrap Complete --"