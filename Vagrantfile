# see https://github.com/lxc/incus/releases
# renovate: datasource=github-releases depName=lxc/incus extractVersion=(incus-)?(?<version>.+)
INCUS_VERSION = "0.1"

# see https://linuxcontainers.org/incus/docs/main/reference/storage_drivers/#storage-drivers
# see https://linuxcontainers.org/incus/docs/main/reference/storage_btrfs/
# see https://linuxcontainers.org/incus/docs/main/reference/storage_zfs/
STORAGE_DRIVER = "btrfs" # or zfs.

VM_CPUS       = 4
VM_MEMORY_MB  = 4*1024

Vagrant.configure("2") do |config|
  config.vm.provider "libvirt" do |lv, config|
    lv.cpu_mode = "host-passthrough"
    lv.nested = true
    lv.keymap = "pt"
  end

  config.vm.define :incus do |config|
    config.vm.box = "debian-12-amd64"
    config.vm.hostname = "incus.test"
    config.vm.provider "libvirt" do |lv, config|
      lv.cpus = VM_CPUS
      lv.memory = VM_MEMORY_MB
      lv.storage :file, :serial => "incus", :size => "60G", :bus => "scsi", :discard => "unmap", :cache => "unsafe"
      config.vm.synced_folder ".", "/vagrant", type: "nfs", nfs_version: "4.2", nfs_udp: false
    end
    config.vm.provision "shell", path: "provision-base.sh"
    config.vm.provision "shell", path: "provision-systemd-networkd.sh"
    config.vm.provision "reload"
    config.vm.provision "shell", path: "provision-incus.sh", args: [INCUS_VERSION, STORAGE_DRIVER]
  end
end
