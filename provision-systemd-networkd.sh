#!/bin/bash
set -euxo pipefail

# see https://wiki.debian.org/SystemdNetworkd
# see https://github.com/lxc/incus/issues/146


#
# replace ifupdown with systemd-networkd.
cat >/etc/systemd/network/vagrant.network <<'EOF'
[Match]
Name=eth0

[Network]
DHCP=ipv4
EOF
systemctl enable systemd-networkd


#
# install polkitd.
# NB without polkitd, journalctl -u systemd-networkd will show the following
#    error:
#       systemd-networkd[335]: Could not set hostname: Access denied
apt-get install -y polkitd


#
# remove ifupdown and its configuration.

rm /etc/network/interfaces
apt-get remove -y --purge ifupdown
