# About

My [Incus](https://github.com/lxc/incus) playground.

This will:

* Install [Incus](https://github.com/lxc/incus).
  * Set up projects:
    * `foo`.
    * `bar`.
* Install [Keycloak](https://github.com/keycloak/keycloak) as the [Incus authentication provider](https://linuxcontainers.org/incus/docs/main/authentication/#authentication-openid) (a OpenID Connect (OIDC) provider).
  * Set up users:
    * `alice`.
    * `bob`.
* Install [OpenFGA](https://github.com/openfga/openfga) as the [Incus authorization provider](https://linuxcontainers.org/incus/docs/main/authorization/#open-fine-grained-authorization-openfga).
  * Set up user authorizations:
    * For `alice`:
      * Grant the `admin` role on the `incus` server.
    * For `bob`:
      * Grant the `operator` role on the `foo` project.

# Usage

Install the [Base Debian 12 UEFI Box](https://github.com/rgl/debian-vagrant).

Add the following entries to your `hosts` file:

```
10.0.0.10 pandora.incus.test
10.0.0.20 incus.test
```

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

# run a system container.
incus launch images:debian/12 debian-ct
incus info debian-ct
incus config show debian-ct
incus exec debian-ct -- cat /etc/os-release
incus exec debian-ct -- ip addr
incus exec debian-ct -- mount
incus exec debian-ct -- df -h
incus exec debian-ct -- ps axw

# run a application container.
incus remote add docker https://docker.io --protocol oci
incus launch docker:debian:12-slim debian-app-ct
incus info debian-app-ct
incus config show debian-app-ct
incus exec debian-app-ct -- bash -c 'apt-get update && apt-get install -y iproute2 procps'
incus exec debian-app-ct -- cat /etc/os-release
incus exec debian-app-ct -- ip addr
incus exec debian-app-ct -- mount
incus exec debian-app-ct -- df -h
incus exec debian-app-ct -- ps axw

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
if [ -n "$(incus storage info default | grep 'driver: btrfs')" ]; then
    btrfs filesystem show
    btrfs filesystem df -h /var/lib/incus/storage-pools/default
    btrfs subvolume list -t /var/lib/incus/storage-pools/default
fi
if [ -n "$(incus storage info default | grep 'driver: zfs')" ]; then
    zfs list
    zfs get all incus/containers/debian-ct
    zfs get all incus/virtual-machines/debian-vm
fi
nft list ruleset

# stop and delete.
incus stop debian-ct
incus stop debian-app-ct
incus stop debian-vm
incus delete debian-ct
incus delete debian-app-ct
incus delete debian-vm
```

Access Keycloak at:

* https://pandora.incus.test:8443
* https://pandora.incus.test:8443/realms/pandora/account

Access Incus at:

* https://incus.test:8443

Test the OIDC authentication:

```bash
vagrant ssh pandora
# login as alice:alice (as defined in keycloak/main.tf).
# then, repeat this whole section as bob:bob.
# NB you can manage your authentication at:
#     https://pandora.incus.test:8443/realms/pandora/account
incus remote add incus.test --auth-type oidc
incus remote list
incus info incus.test:
incus info incus.test: | grep auth_ # check your user information.
incus project list incus.test:
incus launch images:debian/12 incus.test:debian-ct
incus list incus.test:
incus list incus.test: --all-projects
incus config show incus.test:debian-ct
incus exec incus.test:debian-ct -- cat /etc/os-release
incus stop incus.test:debian-ct
incus delete incus.test:debian-ct
incus remote remove incus.test
exit
```

Play with OpenFGA:

```bash
vagrant ssh pandora
sudo -i
export FGA_STORE_ID="$(jq -r .store.id /vagrant/shared/openfga-incus.json)"
fga store list
fga tuple read
exit
exit
```

Destroy the environment:

```bash
vagrant destroy -f
```

# Update dependencies

List this repository dependencies (and which have newer versions):

```bash
export GITHUB_COM_TOKEN='YOUR_GITHUB_PERSONAL_TOKEN'
./renovate.sh
```

# References

* [Incus documentation](https://linuxcontainers.org/incus/docs/main/)
  * [Incus Authentication](https://linuxcontainers.org/incus/docs/main/authentication/#authentication-openid) (OpenID Connect (OIDC))
    * [Keycloak](https://github.com/keycloak/keycloak)
  * [Incus Authorization (OpenFGA)](https://linuxcontainers.org/incus/docs/main/authorization/#open-fine-grained-authorization-openfga)
    * [OpenFGA](https://github.com/openfga/openfga)
* [Incus repository](https://github.com/lxc/incus)
* [Incus package repository](https://github.com/zabbly/incus)
* [distrobuilder: System container and VM image builder for Incus and LXC](https://github.com/lxc/distrobuilder)
* [Images for containers and virtual machines](https://images.linuxcontainers.org/)
* [BTRFS documentation](https://btrfs.readthedocs.io/en/latest/)
* [BTRFS Incus storage driver](https://linuxcontainers.org/incus/docs/main/reference/storage_btrfs/)
* [BTRFS Debian wiki](https://wiki.debian.org/Btrfs)
* [ZFS Debian wiki](https://wiki.debian.org/ZFS)
* [ZFS Incus storage driver](https://linuxcontainers.org/incus/docs/main/reference/storage_zfs/)
* [ZFS repository](https://github.com/openzfs/zfs)
