resource "libvirt_cloudinit_disk" "cockroach_cloudinit" {
  for_each = local.all_cockroach_nodes

  name           = each.value.cloudinit
  pool           = libvirt_pool.deployment.name
  meta_data      = templatefile("${path.module}/cloud-init/meta_data.cfg.tpl", { machine_id = random_uuid.machine_id[each.key].result, hostname = each.value.name })
  network_config = templatefile("${path.module}/cloud-init/network_config.cfg.tpl", {})

  user_data = data.template_cloudinit_config.cockroach_config[each.key].rendered
}

data "template_cloudinit_config" "cockroach_config" {
  for_each = local.all_cockroach_nodes

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
    content: ${base64encode(tls_self_signed_cert.ca_cert.cert_pem)}
    path: /opt/cockroach/tls-pub/ca.crt
    owner: cockroach:cockroach
    permissions: 0600    
  - encoding: b64
    content: ${base64encode(tls_private_key.ca_key.private_key_pem)}
    path: /opt/cockroach/tls-priv/ca.key
    owner: cockroach:cockroach
    permissions: 0400
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
EOT
  }

  part {
    content_type = "text/x-shellscript-per-instance"
    content = templatefile("${path.module}/cloud-init/cockroach/setup_cockroach.sh.tpl",
      {
        server_certificates_data = local.cockroach_certificates[each.value.name],
        init_cluster = each.value.index == 0
        all_nodes = join(",", [for s in local.all_cockroach_nodes : "${s.fqdn}:26257"])
    })
  }
}

resource "libvirt_domain" "cockroach-machine" {
  for_each = local.all_cockroach_nodes

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
  cloudinit = libvirt_cloudinit_disk.cockroach_cloudinit[each.key].id

  cpu {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.cockroach-node-vm-disk[each.key].id
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
    libvirt_cloudinit_disk.cockroach_cloudinit
  ]
}

resource "libvirt_volume" "cockroach-node-vm-disk" {
  for_each = local.all_cockroach_nodes

  #   # workaround: depend on libvirt_ignition.ignition[each.key], otherwise the VM will use the old disk when the user-data changes
  #   name           = "${each.value.name}-${md5(libvirt_ignition.worker_node_ignition[each.key].id)}.qcow2"
  name             = each.value.volume
  pool             = libvirt_pool.deployment.name
  base_volume_pool = var.base_volume_pool
  base_volume_name = var.cockroachdb_volume_name
}