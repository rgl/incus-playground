#!/bin/bash
set -euxo pipefail

POSTGRES_FQDN="${1}"

# install postgres.
apt-get install -y --no-install-recommends postgresql

# listen at all addresses.
sed -i -E 's,^#?(listen_addresses\s*=).+?(#.+)?,\1 '"'*'"'\2,g' /etc/postgresql/17/main/postgresql.conf
cat >>/etc/postgresql/17/main/pg_hba.conf <<EOF
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all             all             0.0.0.0/0               scram-sha-256
EOF

# setup tls.
install -o postgres -g postgres -m 444 /vagrant/shared/example-ca/$POSTGRES_FQDN-crt.pem /etc/postgresql/17/main
install -o postgres -g postgres -m 400 /vagrant/shared/example-ca/$POSTGRES_FQDN-key.pem /etc/postgresql/17/main
sed -i -E 's,^#?(ssl\s*=).+,\1 on,g' /etc/postgresql/17/main/postgresql.conf
sed -i -E 's,^#?(ssl_ciphers\s*=).+,\1 '"'HIGH:!aNULL'"',g' /etc/postgresql/17/main/postgresql.conf
sed -i -E 's,^#?(ssl_cert_file\s*=).+,\1 '"'/etc/postgresql/17/main/$POSTGRES_FQDN-crt.pem'"',g' /etc/postgresql/17/main/postgresql.conf
sed -i -E 's,^#?(ssl_key_file\s*=).+,\1 '"'/etc/postgresql/17/main/$POSTGRES_FQDN-key.pem'"',g' /etc/postgresql/17/main/postgresql.conf

# enable detailed logging.
# see https://www.postgresql.org/docs/17/runtime-config-logging.html
sed -i -E 's,^#?(logging_collector\s*=).+,\1 on,g' /etc/postgresql/17/main/postgresql.conf # default is off. # XXX postgres on ubuntu is writting to log files?
sed -i -E 's,^#?(log_min_messages\s*=).+,\1 info,g' /etc/postgresql/17/main/postgresql.conf # default is warning.
sed -i -E 's,^#?(log_statement\s*=).+,\1 '"'all'"',g' /etc/postgresql/17/main/postgresql.conf # default is 'none'.
sed -i -E 's,^#?(log_connections\s*=).+,\1 on,g' /etc/postgresql/17/main/postgresql.conf # default is 'off'.
sed -i -E 's,^#?(log_disconnections\s*=).+,\1 on,g' /etc/postgresql/17/main/postgresql.conf # default is 'off'.
echo 'You can see the postgresql logs with: tail -f /var/lib/postgresql/17/main/log/*.log'

# restart postgres.
systemctl restart postgresql

# show version, users and databases.
pushd /
sudo -sHu postgres psql -c 'select version()'
sudo -sHu postgres psql -c '\du'
sudo -sHu postgres psql -l
popd
