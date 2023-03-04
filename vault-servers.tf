resource "libvirt_cloudinit_disk" "vault_cloudinit" {
  for_each = local.all_vault_nodes

  name           = each.value.cloudinit
  pool           = libvirt_pool.deployment.name
  meta_data      = templatefile("${path.module}/cloud-init/meta_data.cfg.tpl", { machine_id = random_uuid.machine_id[each.key].result, hostname = each.value.name })
  network_config = templatefile("${path.module}/cloud-init/network_config.cfg.tpl", {})

  user_data = data.template_cloudinit_config.vault_config[each.key].rendered
}

data "template_cloudinit_config" "vault_config" {
  for_each = local.all_vault_nodes

  gzip          = false # does not work with NoCloud ds?!?
  base64_encode = false # does not work with NoCloud ds?!?

  part {
    content_type = "text/cloud-config"
    content      = <<EOT
#cloud-config

preserve_hostname: false
hostname: ${each.value.name}
fqdn: ${each.value.fqdn}
prefer_fqdn_over_hostname: true

ssh_pwauth: True
chpasswd:
  expire: false
  users:
    - name: ubuntu
      password: ubuntu
      type: text  

ssh_authorized_keys:
  - "${each.value.ssh_key}"  

ca_certs:
  trusted:
    - |
      ${indent(6, tls_self_signed_cert.ca_cert.cert_pem)}

write_files:
  - encoding: b64
    content: ${base64encode(tls_private_key.ssh.private_key_pem)}
    path: /home/ubuntu/.ssh/id_rsa
    owner: ubuntu:ubuntu
    permissions: 0600
    defer: true
  - encoding: b64
    content: ${base64encode(data.template_file.etc_hosts.rendered)}
    path: /etc/hosts
    append: true
  - encoding: b64
    content: ${base64encode(file("${path.module}/cloud-init/vault/unseal.sh"))}
    path: /home/ubuntu/unseal.sh
    owner: ubuntu:ubuntu
    permissions: '0700'    
  - encoding: b64
    content: ${base64encode(templatefile("${path.module}/cloud-init/vault/migrate.hcl", {postgres = local.postgres.fqdn, cockroach = local.first_cockroach_server.fqdn }))}
    path: /home/ubuntu/migrate.hcl
    owner: ubuntu:ubuntu
    permissions: '0600'    
  - encoding: b64
    content: ${base64encode(templatefile("${path.module}/cloud-init/vault/switch.sh", {postgres = local.postgres.fqdn, cockroach = local.first_cockroach_server.fqdn }))}
    path: /home/ubuntu/switch.sh
    owner: ubuntu:ubuntu
    permissions: '0700'    
  - encoding: b64
    content: ${base64encode(file("${path.module}/cloud-init/vault/start-vault-and-unseal.sh"))}
    path: /home/ubuntu/start-vault-and-unseal.sh
    owner: ubuntu:ubuntu
    permissions: '0700'    
EOT
  }

  part {
    content_type = "text/x-shellscript-per-instance"
    content = templatefile("${path.module}/cloud-init/vault/setup_vault_server.sh.tpl",
      {
        vault_certificates_data = local.vault_certificates
        postgres                = local.postgres.fqdn
    })
  }
}

resource "libvirt_domain" "vault-machine" {
  for_each = local.all_vault_nodes

  name   = each.value.name
  vcpu   = var.virtual_cpus_nodes
  memory = var.virtual_memory_nodes

  autostart = false
  machine   = "q35"

  xml { # para a q35 o cdrom necessita de ser sata
    xslt = file("lib-virt/q35-cdrom-model.xslt")
  }
  qemu_agent = true

  firmware  = "${local.uefi_location_files}/OVMF_CODE.fd"
  cloudinit = libvirt_cloudinit_disk.vault_cloudinit[each.key].id

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.vault-node-vm-disk[each.key].id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  network_interface {
    network_id     = each.value.network_id
    hostname       = each.value.name
    addresses      = [each.value.ip]
    wait_for_lease = true
  }

  depends_on = [
    libvirt_cloudinit_disk.vault_cloudinit
  ]
}

resource "libvirt_volume" "vault-node-vm-disk" {
  for_each = local.all_vault_nodes

  #   # workaround: depend on libvirt_ignition.ignition[each.key], otherwise the VM will use the old disk when the user-data changes
  #   name           = "${each.value.name}-${md5(libvirt_ignition.worker_node_ignition[each.key].id)}.qcow2"
  name             = each.value.volume
  pool             = libvirt_pool.deployment.name
  base_volume_pool = var.base_volume_pool
  base_volume_name = var.vault_volume_name
}