#!/bin/bash
set -euxo pipefail

cat >>/etc/hosts <<EOF
$1
EOF
