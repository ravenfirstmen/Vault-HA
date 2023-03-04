# network
variable "deployment_name" {
  type    = string
  default = "vault"
}

variable "network_zone1_cidr" {
  type    = string
  default = "192.168.200.0/24"
}

variable "network_zone2_cidr" {
  type    = string
  default = "192.168.210.0/24"
}

variable "network_domain" {
  type    = string
  default = "vault-ha.local"
}

# Volumes
variable "base_volume_pool" {
  type    = string
  default = "Ubuntu20.04"
}

variable "vault_volume_name" {
  type    = string
  default = "Ubuntu-20.04-LTS-With-Vault.qcow2"
}

variable "postgres_volume_name" {
  type    = string
  default = "Ubuntu-20.04-LTS-With-Postgres.qcow2"
}

variable "cockroachdb_volume_name" {
  type    = string
  default = "Ubuntu-20.04-LTS-With-Cockroachdb.qcow2"
}

variable "zone1_vault_n_nodes" {
  type        = number
  description = "number vault of nodes"
  default     = 3
}

variable "zone2_vault_n_nodes" {
  type        = number
  description = "number vault of nodes"
  default     = 0
}

variable "zone1_cockroach_n_nodes" {
  type        = number
  description = "number cockroach of nodes"
  default     = 1
}

variable "zone2_cockroach_n_nodes" {
  type        = number
  description = "number cockroach of nodes"
  default     = 0
}

variable "virtual_memory_nodes" {
  type        = number
  default     = 2048
  description = "Virtual RAM in MB for nodes"
}

variable "virtual_cpus_nodes" {
  type        = number
  default     = 2
  description = "Number of virtual CPUs for worker nodes"
}
