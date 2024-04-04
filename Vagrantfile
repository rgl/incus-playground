ENV["VAGRANT_NO_PARALLEL"] = "yes"

# see https://github.com/lxc/incus/releases
# NB incus tag has a three component version number of MAJOR.MINOR.PATCH but the
#    package is versioned differently, as MAJOR.MINOR-DATE, so, we use a two
#    component version here.
#    see https://github.com/lxc/incus/issues/240#issuecomment-1853333228
# renovate: datasource=github-releases depName=lxc/incus extractVersion=v(?<version>\d+\.\d+)(\.\d+)?
INCUS_VERSION = "6.0"

# see https://github.com/lxc/incus/releases
# renovate: datasource=github-releases depName=lxc/incus
INCUS_CLIENT_VERSION = "6.0.0"

# see https://github.com/lxc/incus/releases
# see https://github.com/zabbly/incus
# see https://github.com/canonical/lxd-ui
INCUS_UI_CANONICAL_VERSION = INCUS_VERSION

# see https://linuxcontainers.org/incus/docs/main/reference/storage_drivers/#storage-drivers
# see https://linuxcontainers.org/incus/docs/main/reference/storage_btrfs/
# see https://linuxcontainers.org/incus/docs/main/reference/storage_zfs/
INCUS_STORAGE_DRIVER = "btrfs" # or zfs.

PANDORA_VM_CPUS       = 4
PANDORA_VM_MEMORY_MB  = 2*1024
PANDORA_IP_ADDRESS    = "10.0.0.10"
PANDORA_FQDN          = "pandora.incus.test"

INCUS_VM_CPUS         = 4
INCUS_VM_MEMORY_MB    = 4*1024
INCUS_IP_ADDRESS      = "10.0.0.20"
INCUS_FQDN            = "incus.test"

CONFIG_EXTRA_HOSTS = """
#{PANDORA_IP_ADDRESS} #{PANDORA_FQDN}
#{INCUS_IP_ADDRESS} #{INCUS_FQDN}
"""

Vagrant.configure("2") do |config|
  config.vm.provider "libvirt" do |lv, config|
    lv.cpu_mode = "host-passthrough"
    lv.nested = true
    lv.keymap = "pt"
  end

  config.vm.define :pandora do |config|
    config.vm.box = "debian-12-amd64"
    config.vm.hostname = PANDORA_FQDN
    config.vm.provider "libvirt" do |lv, config|
      lv.cpus = PANDORA_VM_CPUS
      lv.memory = PANDORA_VM_MEMORY_MB
      config.vm.synced_folder ".", "/vagrant", type: "nfs", nfs_version: "4.2", nfs_udp: false
    end
    config.vm.network "private_network", ip: PANDORA_IP_ADDRESS, libvirt__forward_mode: "route", libvirt__dhcp_enabled: false
    config.vm.provision "shell", path: "provision-extra-hosts.sh", args: [CONFIG_EXTRA_HOSTS]
    config.vm.provision "shell", path: "provision-base.sh"
    config.vm.provision "shell", path: "provision-certification-authority.sh"
    config.vm.provision "shell", path: "provision-certificate.sh", args: [PANDORA_FQDN]
    config.vm.provision "shell", path: "provision-certificate.sh", args: [INCUS_FQDN]
    config.vm.provision "shell", path: "provision-terraform.sh"
    config.vm.provision "shell", path: "provision-postgresql.sh", args: [PANDORA_FQDN]
    config.vm.provision "shell", path: "provision-openfga.sh", args: [PANDORA_FQDN]
    config.vm.provision "shell", path: "provision-openfga-cli.sh", args: [PANDORA_FQDN]
    config.vm.provision "shell", path: "keycloak/provision-keycloak.sh", args: [PANDORA_FQDN]
    config.vm.provision "shell", path: "provision-incus-client.sh", args: [INCUS_CLIENT_VERSION]
    config.vm.provision "shell", path: "provision-openfga-incus.sh"
  end

  config.vm.define :incus do |config|
    config.vm.box = "debian-12-amd64"
    config.vm.hostname = INCUS_FQDN
    config.vm.provider "libvirt" do |lv, config|
      lv.cpus = INCUS_VM_CPUS
      lv.memory = INCUS_VM_MEMORY_MB
      lv.storage :file, :serial => "incus", :size => "60G", :bus => "scsi", :discard => "unmap", :cache => "unsafe"
      config.vm.synced_folder ".", "/vagrant", type: "nfs", nfs_version: "4.2", nfs_udp: false
    end
    config.vm.network "private_network", ip: INCUS_IP_ADDRESS, libvirt__forward_mode: "route", libvirt__dhcp_enabled: false
    config.vm.provision "shell", path: "provision-extra-hosts.sh", args: [CONFIG_EXTRA_HOSTS]
    config.vm.provision "shell", path: "provision-base.sh"
    config.vm.provision "shell", path: "provision-certification-authority.sh"
    config.vm.provision "shell", path: "provision-systemd-networkd.sh", args: [INCUS_IP_ADDRESS]
    config.vm.provision "reload"
    config.vm.provision "shell", path: "provision-openfga-cli.sh", args: [PANDORA_FQDN]
    config.vm.provision "shell", path: "provision-incus.sh", args: [PANDORA_FQDN, INCUS_FQDN, INCUS_VERSION, INCUS_STORAGE_DRIVER]
    config.vm.provision "shell", path: "provision-incus-ui-canonical.sh", args: [PANDORA_FQDN, INCUS_FQDN, INCUS_UI_CANONICAL_VERSION]
  end
end
