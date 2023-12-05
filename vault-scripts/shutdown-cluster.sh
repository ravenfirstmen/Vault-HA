#!/bin/bash

TF_PROVISIONED_DOMAINS=$(terraform -chdir=.. output -json vault_nodes | jq -r '.[].name')

for domain in ${TF_PROVISIONED_DOMAINS} ; do
    if [[ $(virsh --connect qemu:///system list | grep $domain | grep 'running$') ]] ; then
        virsh --connect qemu:///system shutdown "$domain"
    fi

done