
resource "tls_private_key" "cockroach_server_key" {
  for_each = local.all_cockroach_nodes

  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "cockroach_server_cert" {
  for_each = local.all_cockroach_nodes

  private_key_pem = tls_private_key.cockroach_server_key[each.key].private_key_pem

  subject {
    common_name  = "node"
    organization = "Virtual"
  }

  ip_addresses = [
    each.value.ip,
    "127.0.0.1",
  ]

  dns_names = [
    each.value.name,
    each.value.fqdn,
    "localhost"
  ]
}

resource "tls_locally_signed_cert" "cockroach_server_signed_cert" {
  for_each = local.all_cockroach_nodes

  cert_request_pem = tls_cert_request.cockroach_server_cert[each.key].cert_request_pem

  ca_private_key_pem = tls_private_key.ca_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca_cert.cert_pem

  allowed_uses = [
    "data_encipherment",
    "digital_signature",
    "key_encipherment",
    "client_auth",
    "server_auth",
  ]

  validity_period_hours = 8760
}

locals {
  cockroach_certificates_data = {
    for s in local.all_cockroach_nodes : s.name => {
      cockroach_ca   = base64encode(tls_self_signed_cert.ca_cert.cert_pem)
      cockroach_cert = base64encode(tls_locally_signed_cert.cockroach_server_signed_cert[s.key].cert_pem)
      cockroach_pk   = base64encode(tls_private_key.cockroach_server_key[s.key].private_key_pem)
    }
  }

  cockroach_certificates = {
    for s in local.all_cockroach_nodes : s.name => base64encode(jsonencode(local.cockroach_certificates_data[s.name]))
  }
}
