#!/usr/bin/env bash

vault_servers=($(terraform -chdir=.. output -json vault_nodes | jq -r '.[].address'))

for server in ${vault_servers[@]};
do
    echo "Starting server $server ..."
    ssh -i ../ssh-vault-key.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$server './start-vault-and-unseal.sh'
done