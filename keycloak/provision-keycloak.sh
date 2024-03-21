#!/bin/bash
set -euxo pipefail

domain="${1:-pandora.incus.test}"
base_url="https://$domain:8443"

# see https://github.com/keycloak/keycloak/releases
# renovate: datasource=github-releases depName=keycloak/keycloak
keycloak_version='24.0.1'

# install dependencies.
apt-get install -y unzip openjdk-17-jre-headless

# create the keycloak system user.
groupadd --system keycloak
adduser \
    --system \
    --disabled-login \
    --no-create-home \
    --gecos '' \
    --ingroup keycloak \
    --home /opt/keycloak \
    keycloak

# download and install.
keycloak_artifact_url="https://github.com/keycloak/keycloak/releases/download/${keycloak_version}/keycloak-${keycloak_version}.zip"
t="$(mktemp -q -d --suffix=.keycloak)"
wget -qO "$t/keycloak.zip" "$keycloak_artifact_url"
unzip "$t/keycloak.zip" -d "$t"
rm -rf /opt/keycloak
mv "$t/keycloak-${keycloak_version}" /opt/keycloak
chown -R keycloak:keycloak /opt/keycloak
rm -rf "$t"

# configure.
# NB this uses a non-production configuration.
# see https://www.keycloak.org/server/all-config
# see https://www.keycloak.org/server/configuration
# see https://www.keycloak.org/server/configuration-production
mv /opt/keycloak/conf/keycloak{,.orig}.conf
cat >/opt/keycloak/conf/keycloak.conf <<EOF
hostname=$domain
https-certificate-file=\${kc.home.dir}/conf/$domain-crt.pem
https-certificate-key-file=\${kc.home.dir}/conf/$domain-key.pem
EOF
install -o root -g keycloak -m 444 "/vagrant/shared/example-ca/$domain-crt.pem" /opt/keycloak/conf
install -o root -g keycloak -m 440 "/vagrant/shared/example-ca/$domain-key.pem" /opt/keycloak/conf

# build.
sudo -sHu keycloak bash -euox pipefail <<'EOF'
/opt/keycloak/bin/kc.sh build
/opt/keycloak/bin/kc.sh show-config
EOF

# start.
cat >/etc/systemd/system/keycloak.service <<'EOF'
[Unit]
Description=Keycloak
After=network.service

[Service]
Type=simple
User=keycloak
Group=keycloak
Environment=KEYCLOAK_ADMIN=admin
Environment=KEYCLOAK_ADMIN_PASSWORD=admin
ExecStart=/opt/keycloak/bin/kc.sh start --optimized
WorkingDirectory=/opt/keycloak
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
systemctl enable keycloak
systemctl start keycloak

# wait for keycloak to be available.
function wait-for-oidc {
    while [ -z "$(wget -qO- "$1" | jq -r .issuer)" ]; do
        sleep 5
    done
}
wait-for-oidc "$base_url/realms/master/.well-known/openid-configuration"

# configure.
pushd /vagrant/keycloak
rm -f terraform.tfstate .terraform/terraform.tfstate
terraform init
terraform apply -auto-approve
terraform output -json incus_oidc_client \
    | jq \
    > /vagrant/shared/keycloak-incus-oidc-client.json
wait-for-oidc "$base_url/realms/pandora/.well-known/openid-configuration"
wget -qO- "$base_url/realms/pandora/.well-known/openid-configuration" \
    | jq \
    > /vagrant/shared/keycloak-incus-oidc-configuration.json
if [ -z "$(jq -r .issuer /vagrant/shared/keycloak-incus-oidc-configuration.json)" ]; then
    echo "failed to get the pandora oidc configuration"
    exit 1
fi
popd

# show information.
cat <<EOF

Keycloak is available at:

    $base_url

Keycloak user account console:

    $base_url/realms/pandora/account

Login as:

    admin
    admin

EOF
