#!/bin/bash
# ============================================================
#  OctaSec | MISP v.2.5 Installation (Ubuntu 24.04)
#  Author: DefSec 2026
# ============================================================

echo "=== [1/10] Updating system and installing prerequisites ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl unzip gnupg-agent software-properties-common

# Create dedicated MISP user
echo "=== [2/10] Creating user misp ==="
sudo adduser misp --gecos "MISP,,," --disabled-password
echo "misp:M1$p2026#! " | sudo chpasswd
sudo usermod -aG sudo,staff,www-data misp

# Install MISP
echo "=== [3/10] Downloading and running official MISP 2.5 installer ==="
sudo -i -u misp bash << 'EOF'
cd /tmp
wget --no-cache -O INSTALL.sh https://raw.githubusercontent.com/MISP/MISP/2.5/INSTALL/INSTALL.ubuntu2404.sh
chmod +x INSTALL.sh
sudo bash INSTALL.sh
EOF

# Configure local DNS and BaseURL
echo "=== [4/10] Configuring local DNS and BaseURL ==="
echo "127.0.0.1 misp.local" | sudo tee -a /etc/hosts
sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting MISP.baseurl https://misp.local

# Enable SSL
echo "=== [5/10] Enabling Apache SSL ==="
sudo a2enmod ssl
sudo a2ensite default-ssl || true
sudo a2ensite misp-ssl.conf || sudo a2ensite misp.conf
sudo systemctl reload apache2

# Adjust password policy (simple regex for demo)
echo "=== [6/10] Adjusting password policy for demo ==="
sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.password_policy_length" 8
sudo -u www-data /var/www/MISP/app/Console/cake Admin setSetting "Security.password_policy_complexity" "^(?=.{8,}).*$"

# Reset admin password
echo "=== [7/10] Resetting admin password ==="
sudo -u www-data /var/www/MISP/app/Console/cake user list
sudo -u www-data /var/www/MISP/app/Console/cake Password admin-misp@mahatek.net "def$econ2026#!"

# Load feeds
echo "=== [8/10] Enabling default feeds ==="
sudo -u www-data /var/www/MISP/app/Console/cake Server cacheFeed 1
sudo -u www-data /var/www/MISP/app/Console/cake Server fetchFeed 1

# Install Dashboard
echo "=== [9/10] Installing MISP Dashboard (optional) ==="
sudo apt install -y redis-server python3-venv python3-pip
cd /var/www
sudo git clone https://github.com/MISP/misp-dashboard.git
sudo chown -R www-data:www-data misp-dashboard
cd misp-dashboard
python3 -m venv venv
./venv/bin/pip install -U pip wheel
./venv/bin/pip install -r requirements.txt
sudo tee /etc/systemd/system/misp-dashboard.service >/dev/null <<'UNIT'
[Unit]
Description=MISP Dashboard
After=network.target redis-server.service

[Service]
User=www-data
Group=www-data
WorkingDirectory=/var/www/misp-dashboard
ExecStart=/var/www/misp-dashboard/venv/bin/python3 /var/www/misp-dashboard/app.py
Restart=always

[Install]
WantedBy=multi-user.target
UNIT
sudo systemctl daemon-reload
sudo systemctl enable --now misp-dashboard

# Restart services
echo "=== [10/10] Restarting Apache ==="
sudo systemctl restart apache2

# MISP installation complete
echo "=============================================================="
echo " MISP installation complete!     "
echo " Access: https://localhost:8443  "
echo " Username: admin-misp@defsec.net "
echo " Password: def$econ2026#!        "
echo "=============================================================="
