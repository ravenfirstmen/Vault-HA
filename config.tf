terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.7.1"
    }
    ct = {
      source  = "poseidon/ct"
      version = "0.7.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

