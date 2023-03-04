#!/usr/bin/env bash

INSTANCE_ID=$(cat /etc/machine-id)
echo "Starting deployment cockroach on instance: $INSTANCE_ID"
LOCAL_IPV4=$(hostname -I | sed 's/[[:space:]]//g') 
NODE_NAME=$(hostname) 

COCKROACH_CERTIFICATES_DATA=$(echo "${server_certificates_data}" | base64 --decode)

jq -r .cockroach_cert <<< "$COCKROACH_CERTIFICATES_DATA" | base64 -d > /opt/cockroach/tls-pub/node.crt
jq -r .cockroach_ca <<< "$COCKROACH_CERTIFICATES_DATA" | base64 -d > /opt/cockroach/tls-pub/ca.crt
jq -r .cockroach_pk <<< "$COCKROACH_CERTIFICATES_DATA" | base64 -d > /opt/cockroach/tls-pub/node.key

mkdir -p /opt/cockroach/tls-pub
mkdir -p /opt/cockroach/data

chmod -R 0600 /opt/cockroach/tls-pub/*

cockroach cert create-client root --certs-dir=/opt/cockroach/tls-pub --ca-key=/opt/cockroach/tls-priv/ca.key --lifetime 8760h

chown -R cockroach:cockroach /opt/cockroach

tee /etc/default/cockroach.env << EOF
COCKROACH_ARGS="--certs-dir=/opt/cockroach/tls-pub --store=/opt/cockroach/data --listen-addr=$NODE_NAME:26257 --http-addr=$NODE_NAME:8080 --join=${all_nodes}"
EOF

systemctl enable cockroach
systemctl start cockroach

%{~ if init_cluster ~}

sleep 20

cockroach init --certs-dir=/opt/cockroach/tls-pub --host=$NODE_NAME:26257

sleep 20

cockroach sql --certs-dir=/opt/cockroach/tls-pub --host=$NODE_NAME:26257 -e "CREATE USER vault WITH PASSWORD 'a_vault_strong_password_grin'; GRANT admin To vault;"
cockroach sql --certs-dir=/opt/cockroach/tls-pub --host=$NODE_NAME:26257 -e "CREATE DATABASE IF NOT EXISTS vault; GRANT ALL ON DATABASE vault TO vault WITH GRANT OPTION;"

tee create_tables.sql <<EOF
CREATE TABLE IF NOT EXISTS vault_kv_store ( path STRING, value BYTES, PRIMARY KEY (path) );
CREATE TABLE IF NOT EXISTS vault_ha_locks (
  ha_key                                      TEXT NOT NULL,
  ha_identity                                 TEXT NOT NULL,
  ha_value                                    TEXT ,
  valid_until                                 TIMESTAMP WITH TIME ZONE NOT NULL,
  CONSTRAINT ha_key PRIMARY KEY (ha_key)
);
EOF

#cockroach sql --certs-dir=/opt/cockroach/tls-pub --url "postgres://vault:a_vault_strong_password_grin@$NODE_NAME:26257/vault?sslmode=prefer" -f create_tables.sql

%{~ endif ~}