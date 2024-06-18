#!/bin/bash
set -euxo pipefail

auth_domain="${1:-pandora.incus.test}"; shift || true
domain="${1:-incus.test}"; shift || true
incus_ui_canonical_version="${1:-6.2}"; shift || true
auth_base_url="https://$auth_domain:8443"
base_url="https://$domain:8443"

# install.
incus_ui_canonical_package_version="$(apt-cache madison incus-ui-canonical | awk "/$incus_ui_canonical_version/{print \$3}" | head -1)"
apt-get install -y --no-install-recommends "incus-ui-canonical=$incus_ui_canonical_package_version"

# show summary.
cat <<EOF

Incus UI:

  $base_url

Keycloak user account console:

  $auth_base_url/realms/pandora/account

EOF
