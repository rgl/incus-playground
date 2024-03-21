#!/bin/bash
set -euxo pipefail

# see https://github.com/hashicorp/terraform/releases
# renovate: datasource=github-releases depName=hashicorp/terraform
terraform_version='1.7.5'

# install terraform.
wget -q https://releases.hashicorp.com/terraform/$terraform_version/terraform_${terraform_version}_linux_amd64.zip
unzip terraform_${terraform_version}_linux_amd64.zip
install \
  -m 755 \
  terraform \
  /usr/local/bin
rm terraform terraform_${terraform_version}_linux_amd64.zip
