resource "libvirt_pool" "deployment" {
  name = "${var.deployment_name}-pool"
  type = "dir"
  path = "/Work/KVM/pools/${var.deployment_name}"
}

