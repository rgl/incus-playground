#!/bin/bash
set -euxo pipefail

# create the incus store.
fga store create \
  --name Incus \
  | jq \
  > /vagrant/shared/openfga-incus.json
