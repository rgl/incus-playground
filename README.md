# About

My [Incus](https://github.com/lxc/incus) playground.

# Usage

Install the [Base Debian 12 Box](https://github.com/rgl/debian-vagrant).

Launch the environment:

```bash
vagrant up --provider=libvirt --no-destroy-on-error --no-tty
```

Try executing some workloads:

```bash
# ssh into into the vagrant created VM.
vagrant ssh incus

# switch to root.
sudo -i

# run a container.
incus launch images:debian/12 debian-ct
incus info debian-ct
incus config show debian-ct
incus exec debian-ct -- cat /etc/os-release
incus exec debian-ct -- ip addr
incus exec debian-ct -- mount
incus exec debian-ct -- df -h
incus exec debian-ct -- ps axw

# run a virtual machine.
incus launch images:debian/12 debian-vm --vm
incus info debian-vm
incus config show debian-vm
incus exec debian-vm -- cat /etc/os-release
incus exec debian-vm -- ip addr
incus exec debian-vm -- mount
incus exec debian-vm -- df -h
incus exec debian-vm -- ps axw

# show information.
incus info
incus list
incus image list
btrfs filesystem show
btrfs filesystem df -h /var/lib/incus/storage-pools/default
btrfs subvolume list -t /var/lib/incus/storage-pools/default
nft list ruleset

# stop and delete.
incus stop debian-ct
incus stop debian-vm
incus delete debian-ct
incus delete debian-vm
```

# Update dependencies

List this repository dependencies (and which have newer versions):

```bash
export GITHUB_COM_TOKEN='YOUR_GITHUB_PERSONAL_TOKEN'
./renovate.sh
```

# References

* [Incus documentation](https://linuxcontainers.org/incus/docs/main/)
* [Incus repository](https://github.com/lxc/incus)
* [Incus package repository](https://github.com/zabbly/incus)
* [distrobuilder: System container and VM image builder for Incus and LXC](https://github.com/lxc/distrobuilder)
* [Images for containers and virtual machines](https://images.linuxcontainers.org/)
* [BTRFS](https://btrfs.readthedocs.io/en/latest/)
