#!/bin/bash
set -euxo pipefail

OPENFGA_FQDN="${1}"

# see https://github.com/openfga/cli/releases
# renovate: datasource=github-releases depName=openfga/cli
openfga_cli_version='0.2.6'

# download and install the fga cli.
# see https://github.com/openfga/cli/releases
openfga_cli_artifact_url="https://github.com/openfga/cli/releases/download/v${openfga_cli_version}/fga_${openfga_cli_version}_linux_amd64.tar.gz"
t="$(mktemp -q -d --suffix=.openfga_cli)"
wget -qO "$t/openfga_cli.tgz" "$openfga_cli_artifact_url"
install -d "$t/dist"
tar xf "$t/openfga_cli.tgz" -C "$t/dist"
install -o root -g root -m 755 "$t/dist/fga" /usr/local/bin
rm -rf "$t"

# configure fga.
# see https://github.com/openfga/cli?tab=readme-ov-file#configuration
install /dev/null -m 600 ~/.fga.yaml
cat >~/.fga.yaml <<EOF
api-url: https://$OPENFGA_FQDN:8080
api-token: abracadabra
EOF
