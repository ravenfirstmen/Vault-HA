locals {
  uefi_location_files = "/usr/share/OVMF"
  nvram_location      = "/var/lib/libvirt/qemu/nvram"
}

# https://github.com/dmacvicar/terraform-provider-libvirt/issues/778

locals {

  vault_nodes = {
    for n in range(var.vault_n_nodes) : "vault${n}" => {
      name       = "vault${n}"
      fqdn       = "vault${n}.${var.network_domain}"
      ip         = "${cidrhost(var.network_cidr, n + 10)}"
      ip_cidr    = "${cidrhost(var.network_cidr, n + 10)}/24"
      network_id = libvirt_network.cluster_network.id
      gateway    = local.network_gateway
      volume     = "${var.deployment_name}-vault${n}"
      cloudinit  = "${var.deployment_name}-vault${n}-cloudinit.iso"
      ssh_key    = tls_private_key.ssh.public_key_openssh
      index      = n
      key        = "vault${n}"
    }
  }

  postgres = {
    name       = "postgres"
    fqdn       = "postgres.${var.network_domain}"
    ip         = "${cidrhost(var.network_cidr, 20)}"
    ip_cidr    = "${cidrhost(var.network_cidr, 20)}/24"
    network_id = libvirt_network.cluster_network.id
    gateway    = local.network_gateway
    volume     = "postgres.qcow2"
    cloudinit  = "postgres-cloudinit.iso"
    ssh_key    = tls_private_key.ssh.public_key_openssh
    index      = 1
    key        = "postgres"
  }

}

locals {
  single_servers      = { for s in [local.postgres] : s.name => s }
  all_vault_nodes     = local.vault_nodes
  all_nodes           = merge(local.all_vault_nodes, local.single_servers)
}

locals {
  first_vault_server_key = "vault0"
  first_vault_server     = local.all_vault_nodes[local.first_vault_server_key]
}