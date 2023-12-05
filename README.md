# About

Deploy Vault in HA mode Postgres (QEMU + KVM)

# Build the images (Ubuntu 20.04 based)

Clone the Github repository Packer and build the images first (https://github.com/ravenfirstmen/Packer)

```
git clone https://github.com/ravenfirstmen/Packer.git
cd Packer && packer init . && packer build .
```


# Deployment

Ensure terraform is installed (https://developer.hashicorp.com/terraform/downloads)

```
terraform init && terraform apply
```

# Unseal Vault

**NOTE:** Vault is started sealed. First unseal it

```
cd vault-scripts && ./unseal-vault.sh
```
The `unseal-info.json` contains the unseals keys and the root token


