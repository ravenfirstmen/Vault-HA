resource "random_uuid" "machine_id" {
  for_each = local.all_nodes
}

