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

output "postgres" {
  value = {
    name    = local.postgres.name
    address = local.postgres.ip
  }
}

output "etc_hosts" {
  value = data.template_file.etc_hosts.rendered
}

