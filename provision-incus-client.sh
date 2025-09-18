#!/bin/bash
set -euxo pipefail

# see https://github.com/lxc/incus/releases
incus_client_version="${1:-6.16.0}"

# download and install.
incus_url="https://github.com/lxc/incus/releases/download/v${incus_client_version}/bin.linux.incus.x86_64"
t="$(mktemp -q -d --suffix=.syft)"
wget -qO "$t/incus" "$incus_url"
install -m 755 "$t/incus" /usr/local/bin/
rm -rf "$t"

# install the bash completion script.
incus completion bash >/usr/share/bash-completion/completions/incus
