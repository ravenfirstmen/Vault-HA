resource "libvirt_network" "zone1_cluster_network" {
  name   = "zone1.${var.network_domain}"
  mode   = "nat"
  domain = var.network_domain

  addresses = [var.network_zone1_cidr]

  dns {
    enabled    = true
    local_only = true
  }
}

resource "libvirt_network" "zone2_cluster_network" {
  name   = "zone2.${var.network_domain}"
  mode   = "nat"
  domain = var.network_domain

  addresses = [var.network_zone2_cidr]

  dns {
    enabled    = true
    local_only = true
  }
}

locals {
  zone1_network_gateway = cidrhost(var.network_zone1_cidr, 1) # por omissão em NAT a gateway 1º IP
  zone2_network_gateway = cidrhost(var.network_zone2_cidr, 1) # por omissão em NAT a gateway 1º IP
}

data "template_file" "etc_hosts" {
  template = <<-EOT
#Add these to your /etc/hosts
%{~for s in local.all_nodes}
${format("%s\t%s\t\t%s", s.ip, s.name, s.fqdn)}
%{~endfor}
EOT
}
