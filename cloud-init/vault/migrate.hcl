storage_source "postgresql" {
  connection_url = "postgres://vault:a_vault_strong_password_grin@${postgres}/vault?sslmode=prefer"
}

storage_destination "cockroachdb" {
  connection_url = "postgres://vault:a_vault_strong_password_grin@${cockroach}:26257/vault?sslmode=prefer"
}
