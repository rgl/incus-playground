#!/bin/bash
set -euxo pipefail

POSTGRES_FQDN="${1}"
OPENFGA_FQDN="${1}"

# see https://github.com/openfga/openfga/releases
# renovate: datasource=github-releases depName=openfga/openfga
openfga_version='1.4.0'

# create the openfga system user.
groupadd --system openfga
adduser \
    --system \
    --disabled-login \
    --no-create-home \
    --gecos '' \
    --ingroup openfga \
    --home /opt/openfga \
    openfga

# download and install.
openfga_artifact_url="https://github.com/openfga/openfga/releases/download/v${openfga_version}/openfga_${openfga_version}_linux_amd64.tar.gz"
t="$(mktemp -q -d --suffix=.openfga)"
wget -qO "$t/openfga.tgz" "$openfga_artifact_url"
install -d "$t/dist"
tar xf "$t/openfga.tgz" -C "$t/dist"
rm -rf /opt/openfga
mv "$t/dist" /opt/openfga
chown -R root:root /opt/openfga
rm -rf "$t"

# create the openfga role and database.
pushd /
sudo -sHu postgres psql -c "create role openfga login password 'abracadabra'"
sudo -sHu postgres createdb -E UTF8 -O openfga openfga >/dev/null
/opt/openfga/openfga migrate \
    --datastore-engine postgres \
    --datastore-uri "postgres://openfga:abracadabra@$POSTGRES_FQDN:5432/openfga?sslmode=verify-full"
sudo -sHu postgres psql -c '\du'
sudo -sHu postgres psql -l
popd

# configure.
# see https://openfga.dev/docs/getting-started/setup-openfga/configure-openfga
# see https://github.com/openfga/openfga/blob/v1.4.0/internal/server/config/config.go#L169
# see https://github.com/openfga/openfga/blob/v1.4.0/internal/server/config/config.go#L294
cat >/opt/openfga/config.yaml <<EOF
log:
  format: text
  level: info # none, debug, info, warn, error, panic, fatal.
datastore:
  engine: postgres
  uri: postgres://openfga:abracadabra@$POSTGRES_FQDN:5432/openfga?sslmode=verify-full
authn:
  method: preshared
  preshared:
    keys:
      - abracadabra
grpc:
  addr: :8081
  tls:
    # TODO why enabling this makes openfga fail with the {"error": "context deadline exceeded"} error?
    enabled: false
    key: /opt/openfga/$OPENFGA_FQDN-key.pem
    cert: /opt/openfga/$OPENFGA_FQDN-crt.pem
http:
  enabled: true
  addr: :8080
  tls:
    enabled: true
    key: /opt/openfga/$OPENFGA_FQDN-key.pem
    cert: /opt/openfga/$OPENFGA_FQDN-crt.pem
metrics:
  enabled: true
  addr: :2112
playground:
  enabled: false
  port: 3000
EOF
install -o root -g openfga -m 444 "/vagrant/shared/example-ca/$OPENFGA_FQDN-crt.pem" /opt/openfga
install -o root -g openfga -m 440 "/vagrant/shared/example-ca/$OPENFGA_FQDN-key.pem" /opt/openfga

# start.
cat >/etc/systemd/system/openfga.service <<EOF
[Unit]
Description=openfga
After=network.service

[Service]
Type=simple
User=openfga
Group=openfga
# Environment=OPENFGA_GRPC_TLS_KEY=/opt/openfga/$OPENFGA_FQDN-key.pem
ExecStart=/opt/openfga/openfga run
WorkingDirectory=/opt/openfga
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
systemctl enable openfga
systemctl start openfga
ss -anlp | grep -E '(Address:Port|openfga)'

# show information.
cat <<EOF

OpenFGA is available at:

    grpc://$OPENFGA_FQDN:8081
    https://$OPENFGA_FQDN:8080
    http://$OPENFGA_FQDN:2112/metrics

EOF
