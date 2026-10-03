#!/usr/bin/env bash
# Run only on a new, dedicated Ubuntu 24.04 GF Dad server, as root.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run as root' >&2; exit 1; }
[[ -f /etc/gfdad-bootstrap-complete ]] && { echo 'Already configured; review changes manually.'; exit 1; }
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade
apt-get install -y nginx git curl ufw fail2ban unattended-upgrades logrotate rsync certbot python3-certbot-nginx
timedatectl set-timezone UTC
id gfdad >/dev/null 2>&1 || useradd --create-home --shell /bin/bash gfdad
install -d -m 0755 -o gfdad -g gfdad /var/www/gfdad /var/www/gfdad/releases /var/www/gfdad/shared
install -d -m 0750 -o root -g gfdad /etc/gfdad
install -d -m 0755 /var/www/letsencrypt
install -d -m 0750 -o gfdad -g gfdad /var/log/gfdad
install -m 0640 -o root -g gfdad /dev/null /etc/gfdad/app.env
install -d -m 0700 -o gfdad -g gfdad /home/gfdad/.ssh
install -m 0600 -o gfdad -g gfdad /tmp/gfdad-deploy.pub /home/gfdad/.ssh/authorized_keys
cat > /etc/ssh/sshd_config.d/00-gfdad.conf <<'CONF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
X11Forwarding no
MaxAuthTries 3
AllowUsers ubuntu gfdad
Match User gfdad
    DisableForwarding yes
Match all
CONF
sshd -t
systemctl reload ssh
# Source restriction lives at Lightsail, allowing recovery through its API if your IP changes.
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
cat > /etc/fail2ban/jail.d/gfdad.local <<'CONF'
[sshd]
enabled = true
backend = systemd
maxretry = 5
findtime = 10m
bantime = 1h
CONF
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'CONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONF
cat > /etc/apt/apt.conf.d/52gfdad-security <<'CONF'
Unattended-Upgrade::Automatic-Reboot "false";
CONF
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/gfdad.conf <<'CONF'
[Journal]
Storage=persistent
SystemMaxUse=100M
RuntimeMaxUse=25M
CONF
cat > /etc/logrotate.d/gfdad <<'CONF'
/var/log/gfdad/*.log {
    weekly
    rotate 4
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    su gfdad gfdad
}
CONF
cat > /etc/nginx/conf.d/gfdad-security.conf <<'CONF'
server_tokens off;
CONF
cat > /etc/nginx/sites-available/gfdad <<'CONF'
server {
    listen 80 default_server;
    server_name gfdad.com www.gfdad.com _;
    root /var/www/gfdad/current;
    index index.html;
    access_log /var/log/nginx/gfdad-access.log;
    error_log /var/log/nginx/gfdad-error.log;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy strict-origin-when-cross-origin always;
    add_header X-Frame-Options SAMEORIGIN always;
    gzip on;
    gzip_types text/css application/javascript application/json image/svg+xml;
    location ^~ /.well-known/acme-challenge/ {
        root /var/www/letsencrypt;
    }
    location ~ /\. { deny all; }
    # This is web-server readiness, not an application health check.
    location = /health {
        default_type text/plain;
        return 200 "web-ready\n";
    }
    location / {
        try_files $uri $uri/ =503;
    }
}
CONF
rm -f /etc/nginx/sites-enabled/default
ln -sfn /etc/nginx/sites-available/gfdad /etc/nginx/sites-enabled/gfdad
nginx -t
systemctl enable nginx fail2ban unattended-upgrades
systemctl restart nginx fail2ban systemd-journald
install -m 0755 /tmp/deploy-static.sh /usr/local/bin/gfdad-deploy-static
touch /etc/gfdad-bootstrap-complete
