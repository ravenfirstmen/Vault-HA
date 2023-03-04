#!/bin/bash

sudo systemctl stop vault

sudo sed -i -e "s/${postgres}/${cockroach}:26257/g" /etc/vault.d/vault.hcl
sudo sed -i -e "s/\"postgresql\"/\"cockroachdb\"/g" /etc/vault.d/vault.hcl