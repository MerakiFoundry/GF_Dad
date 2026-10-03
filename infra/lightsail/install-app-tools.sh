#!/usr/bin/env bash
# Run with sudo on the GF Dad Ubuntu 24.04 instance after bootstrap.sh.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run as root' >&2; exit 1; }
[[ -f /etc/gfdad-bootstrap-complete ]] || { echo 'GF Dad baseline is missing' >&2; exit 1; }
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends build-essential python3 pkg-config ca-certificates xz-utils unzip rsync git curl
# Pin the verified Node LTS version. Review newer security releases before updating.
version=v24.21.0
[[ $(uname -m) == x86_64 ]] || { echo 'This installer targets x86_64' >&2; exit 1; }
archive="node-${version}-linux-x64.tar.xz"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
curl --fail --silent --show-error --location "https://nodejs.org/dist/$version/$archive" -o "$archive"
curl --fail --silent --show-error --location "https://nodejs.org/dist/$version/SHASUMS256.txt" -o SHASUMS256.txt
grep "  $archive$" SHASUMS256.txt | sha256sum --check --strict -
install -d -m 0755 /opt/node
if [[ ! -d /opt/node/node-${version}-linux-x64 ]]; then
    tar --extract --xz --file "$archive" --directory /opt/node --no-same-owner
fi
ln -sfn "/opt/node/node-${version}-linux-x64" /opt/node/current
for binary in node npm npx; do
    ln -sfn "/opt/node/current/bin/$binary" "/usr/local/bin/$binary"
done
# Swap uses existing SSD space, not a new AWS disk or paid service.
if [[ ! -e /swapfile-gfdad ]]; then
    fallocate -l 2G /swapfile-gfdad
    chmod 0600 /swapfile-gfdad
    mkswap /swapfile-gfdad
fi
swapon --show=NAME --noheadings | grep -Fxq /swapfile-gfdad || swapon /swapfile-gfdad
grep -q '^/swapfile-gfdad ' /etc/fstab || printf '/swapfile-gfdad none swap sw 0 0\n' >> /etc/fstab
systemctl daemon-reload
printf 'vm.swappiness=10\n' > /etc/sysctl.d/60-gfdad-swap.conf
sysctl -p /etc/sysctl.d/60-gfdad-swap.conf
install -d -m 0755 -o gfdad -g gfdad /var/www/gfdad/source /var/www/gfdad/builds
node --version
npm --version
