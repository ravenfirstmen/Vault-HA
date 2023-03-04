locals {
  uefi_location_files = "/usr/share/OVMF"
  nvram_location      = "/var/lib/libvirt/qemu/nvram"
}

# https://github.com/dmacvicar/terraform-provider-libvirt/issues/778

locals {
  # z1_n_nodes          = var.zone1_n_nodes + 1
  # #cluster_domain_fqdn = "${var.cluster_name}.${var.network_domain}"
  # cluster_domain_fqdn = var.network_domain

  zone1_vault_nodes = {
    for n in range(var.zone1_vault_n_nodes) : "vault${n}-zone1" => {
      name       = "vault${n}"
      fqdn       = "vault${n}.${var.network_domain}"
      ip         = "${cidrhost(var.network_zone1_cidr, n + 10)}"
      ip_cidr    = "${cidrhost(var.network_zone1_cidr, n + 10)}/24"
      network_id = libvirt_network.zone1_cluster_network.id
      gateway    = local.zone1_network_gateway
      volume     = "${var.deployment_name}-vault${n}"
      cloudinit  = "${var.deployment_name}-vault${n}-cloudinit.iso"
      ssh_key    = tls_private_key.ssh.public_key_openssh
      index      = n
      key        = "vault${n}-zone1"
    }
  }

  zone2_vault_nodes = {
    for n in range(var.zone2_vault_n_nodes) : "vault${n}-zone2" => {
      name       = "vault${n + var.zone1_vault_n_nodes}"
      fqdn       = "vault${n + var.zone1_vault_n_nodes}.${var.network_domain}"
      ip         = "${cidrhost(var.network_zone2_cidr, n + 10)}"
      ip_cidr    = "${cidrhost(var.network_zone2_cidr, n + 10)}/24"
      network_id = libvirt_network.zone2_cluster_network.id
      gateway    = local.zone2_network_gateway
      volume     = "${var.deployment_name}-vault${n + var.zone1_vault_n_nodes}"
      cloudinit  = "${var.deployment_name}-vault${n + var.zone1_vault_n_nodes}-cloudinit.iso"
      ssh_key    = tls_private_key.ssh.public_key_openssh
      index      = n + var.zone1_vault_n_nodes
      key        = "vault${n}-zone2"
    }
  }

  zone1_cockroach_nodes = {
    for n in range(var.zone1_cockroach_n_nodes) : "cockroach${n}-zone1" => {
      name       = "cockroach${n}"
      fqdn       = "cockroach${n}.${var.network_domain}"
      ip         = "${cidrhost(var.network_zone1_cidr, n + 30)}"
      ip_cidr    = "${cidrhost(var.network_zone1_cidr, n + 30)}/24"
      network_id = libvirt_network.zone1_cluster_network.id
      gateway    = local.zone1_network_gateway
      volume     = "${var.deployment_name}-cockroach${n}"
      cloudinit  = "${var.deployment_name}-cockroach${n}-cloudinit.iso"
      ssh_key    = tls_private_key.ssh.public_key_openssh
      index      = n
      key        = "cockroach${n}-zone1"
    }
  }

  zone2_cockroach_nodes = {
    for n in range(var.zone2_cockroach_n_nodes) : "cockroach${n}-zone2" => {
      name       = "cockroach${n + var.zone1_cockroach_n_nodes}"
      fqdn       = "cockroach${n + var.zone1_cockroach_n_nodes}.${var.network_domain}"
      ip         = "${cidrhost(var.network_zone2_cidr, n + 30)}"
      ip_cidr    = "${cidrhost(var.network_zone2_cidr, n + 30)}/24"
      network_id = libvirt_network.zone2_cluster_network.id
      gateway    = local.zone2_network_gateway
      volume     = "${var.deployment_name}-cockroach${n + var.zone1_cockroach_n_nodes}"
      cloudinit  = "${var.deployment_name}-cockroach${n + var.zone1_cockroach_n_nodes}-cloudinit.iso"
      ssh_key    = tls_private_key.ssh.public_key_openssh
      index      = n + var.zone1_cockroach_n_nodes
      key        = "cockroach${n}-zone2"
    }
  }


  postgres = {
    name       = "postgres"
    fqdn       = "postgres.${var.network_domain}"
    ip         = "${cidrhost(var.network_zone1_cidr, 20)}"
    ip_cidr    = "${cidrhost(var.network_zone1_cidr, 20)}/24"
    network_id = libvirt_network.zone1_cluster_network.id
    gateway    = local.zone1_network_gateway
    volume     = "postgres.qcow2"
    cloudinit  = "postgres-cloudinit.iso"
    ssh_key    = tls_private_key.ssh.public_key_openssh
    index      = 1
    key        = "postgres"
  }

}

locals {
  single_servers      = { for s in [local.postgres] : s.name => s }
  all_vault_nodes     = merge(local.zone1_vault_nodes, local.zone2_vault_nodes)
  all_cockroach_nodes = merge(local.zone1_cockroach_nodes, local.zone2_cockroach_nodes)
  all_nodes           = merge(local.all_vault_nodes, local.all_cockroach_nodes, local.single_servers)
}

locals {
  first_vault_server_key = "vault0-zone1"
  first_vault_server     = local.all_vault_nodes[local.first_vault_server_key]
  first_cockroach_server_key = "cockroach0-zone1"
  first_cockroach_server     = local.all_cockroach_nodes[local.first_cockroach_server_key]  
}