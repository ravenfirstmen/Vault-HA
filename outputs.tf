output "all-nodes" {
  value = [for s in local.all_nodes : s.name]
}

output "vault_nodes" {
  value = {
    for s in local.all_vault_nodes : s.name => {
      name    = s.name
      address = s.ip
      fqdn    = s.fqdn
    }
  }
}

output "cockroach_nodes" {
  value = {
    for s in local.all_cockroach_nodes : s.name => {
      name    = s.name
      address = s.ip
      fqdn    = s.fqdn
    }
  }
}

output "zone1_vault_nodes" {
  value = {
    for s in local.zone1_vault_nodes : s.name => {
      name    = s.name
      address = s.ip
      fqdn    = s.fqdn
    }
  }
}


output "zone2_vault_nodes" {
  value = {
    for s in local.zone2_vault_nodes : s.name => {
      name    = s.name
      address = s.ip
      fqdn    = s.fqdn
    }
  }
}

output "zone1_cockroach_nodes" {
  value = {
    for s in local.zone1_cockroach_nodes : s.name => {
      name    = s.name
      address = s.ip
      fqdn    = s.fqdn
    }
  }
}


output "zone2_cockroach_nodes" {
  value = {
    for s in local.zone2_cockroach_nodes : s.name => {
      name    = s.name
      address = s.ip
      fqdn    = s.fqdn
    }
  }
}


output "postgres" {
  value = {
    name    = local.postgres.name
    address = local.postgres.ip
  }
}

output "etc_hosts" {
  value = data.template_file.etc_hosts.rendered
}

# scripts
resource "local_file" "create_routes_script" {
  content = <<EOF
  #!/bin/bash

  # Execute this to have routing between the two networks

  sudo iptables -I FORWARD -j ACCEPT -i ${libvirt_network.zone1_cluster_network.bridge} -o ${libvirt_network.zone2_cluster_network.bridge} -s "${var.network_zone1_cidr}" -d "${var.network_zone2_cidr}"
  sudo iptables -I FORWARD -j ACCEPT -i ${libvirt_network.zone2_cluster_network.bridge} -o ${libvirt_network.zone1_cluster_network.bridge} -s "${var.network_zone2_cidr}" -d "${var.network_zone1_cidr}"

  EOF

  filename        = "./zones-routing-create.sh"
  file_permission = "0700"
}

resource "local_file" "delete_routes_script" {
  content = <<EOF
  #!/bin/bash

  # Execute this to remove the previous routing between the two networks

  sudo iptables -D FORWARD -j ACCEPT -i ${libvirt_network.zone1_cluster_network.bridge} -o ${libvirt_network.zone2_cluster_network.bridge} -s "${var.network_zone1_cidr}" -d "${var.network_zone2_cidr}"
  sudo iptables -D FORWARD -j ACCEPT -i ${libvirt_network.zone2_cluster_network.bridge} -o ${libvirt_network.zone1_cluster_network.bridge} -s "${var.network_zone2_cidr}" -d "${var.network_zone1_cidr}"

  EOF

  filename        = "./zones-routing-delete.sh"
  file_permission = "0700"
}