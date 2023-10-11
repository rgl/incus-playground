#!/bin/bash
set -euxo pipefail

# see https://github.com/lxc/incus/releases
incus_version="${1:-0.1}"

storage_driver="${2:-btrfs}"

storage_device='/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_incus'

# install the storage dependencies.
if [ "$storage_driver" == "btrfs" ]; then
  # see https://wiki.debian.org/Btrfs
  apt-get install -y btrfs-progs
elif [ "$storage_driver" == "zfs" ]; then
  # see https://wiki.debian.org/ZFS
  # enable the contrib apt repository section.
  sed -i -E 's,^(deb(-src)? .+),\1 contrib,g' /etc/apt/sources.list
  apt-get update
  # configure the system to accept the zfs incompatible licenses.
  # these anwsers were obtained (after installing zfs-dkms) with:
  #   #sudo debconf-show zfs-dkms
  #   sudo apt-get install debconf-utils
  #   # this way you can see the comments:
  #   sudo debconf-get-selections
  #   # this way you can just see the values needed for debconf-set-selections:
  #   sudo debconf-get-selections | grep -E '^zfs-dkms\s+' | sort
  debconf-set-selections <<EOF
zfs-dkms zfs-dkms/note-incompatible-licenses note
EOF
  apt-get install -y linux-headers-amd64 zfs-dkms zfsutils-linux
  modprobe zfs
else
  echo "unsupported storage driver: $storage_driver"
  exit 1
fi

# install.
# see https://github.com/zabbly/incus#stable-repository
# see https://github.com/zabbly/incus#repository-key
# see https://wiki.debian.org/DebianRepository/Format
# see Debian Bookworkm 12: https://pkgs.zabbly.com/incus/stable/dists/bookworm/Release
# see Debian Bookworkm 12: https://pkgs.zabbly.com/incus/stable/dists/bookworm/main/binary-amd64/Packages
apt-get install -y apt-transport-https software-properties-common
gpg --dearmor >/etc/apt/trusted.gpg.d/zabbly.gpg <<'EOF'
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=8Uc6
-----END PGP PUBLIC KEY BLOCK-----
EOF
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/zabbly.gpg] https://pkgs.zabbly.com/incus/stable $(lsb_release -cs) main" >/etc/apt/sources.list.d/zabbly-incus.list
apt-get update
apt-cache madison incus
incus_package_version="$(apt-cache madison incus | awk "/$incus_version/{print \$3}" | head -1)"
apt-get install -y --no-install-recommends "incus=$incus_package_version"

# kick the tires.
incus version

# configure.
# see https://linuxcontainers.org/incus/docs/main/howto/initialize/
# see https://linuxcontainers.org/incus/docs/main/reference/storage_drivers/#storage-drivers
# see https://linuxcontainers.org/incus/docs/main/reference/storage_btrfs/
# see https://linuxcontainers.org/incus/docs/main/reference/storage_zfs/
if [ "$storage_driver" == "btrfs" ]; then
  storage_pool_config="
  - name: default
    driver: btrfs
    config:
      source: $storage_device"
elif [ "$storage_driver" == "zfs" ]; then
  storage_pool_config="
  - name: default
    driver: zfs
    config:
      source: $storage_device
      zfs.pool_name: incus"
else
  echo "unsupported storage driver: $storage_driver"
  exit 1
fi
incus admin init --preseed <<EOF
storage_pools:$storage_pool_config
networks:
  - name: incusbr0
    type: bridge
    config:
      ipv4.nat: true
      ipv4.address: 10.2.0.1/24
      ipv6.address: none
profiles:
  - name: default
    devices:
      root:
        type: disk
        path: /
        pool: default
      eth0:
        type: nic
        nictype: bridged
        parent: incusbr0
EOF
