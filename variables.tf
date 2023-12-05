# network
variable "deployment_name" {
  type    = string
  default = "vault"
}

variable "network_cidr" {
  type    = string
  default = "192.168.200.0/24"
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

variable "vault_n_nodes" {
  type        = number
  description = "number vault of nodes"
  default     = 3
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
