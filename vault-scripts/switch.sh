#!/usr/bin/env bash

vault_servers=($(terraform -chdir=.. output -json vault_nodes | jq -r '.[].address'))

for server in ${vault_servers[@]};
do
    echo "Switch server $server ..."
    ssh -i ../ssh-vault-key.pem -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" ubuntu@$server './switch.sh'
done