#!/bin/bash
set -euxo pipefail


eth1_ip_address="$1"


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
cat >/etc/systemd/network/incus.network <<EOF
[Match]
Name=eth1

[Network]
Address=$eth1_ip_address/24
#Gateway=10.0.0.1
#DNS=10.0.0.1
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
