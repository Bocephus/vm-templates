packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/proxmox"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

source "proxmox-iso" "rocky-9" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = var.proxmox_insecure_skip_tls_verify
  node                     = var.proxmox_node

  vm_id                 = var.template_id
  vm_name               = var.template_name
  template_name         = var.template_name
  template_description  = "Rocky Linux 9, built ${timestamp()}"

  boot_iso {
    iso_file         = var.iso_file
    iso_storage_pool = var.iso_storage_pool
    unmount          = true
  }

  qemu_agent      = true
  cores           = var.cores
  memory          = var.memory
  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size    = var.disk_size
    storage_pool = var.vm_storage_pool
    type         = "virtio"
  }

  network_adapters {
    bridge   = var.network_bridge
    model    = "virtio"
    firewall = false
  }

  cloud_init              = true
  cloud_init_storage_pool = var.vm_storage_pool

  boot_command = [
    "<up><wait><tab>",
    " inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter>"
  ]
  boot_wait      = "5s"
  http_directory = "http"

  ssh_username = var.ssh_username
  ssh_password = var.ssh_password
  ssh_timeout  = "30m"

  communicator = "ssh"
}

build {
  sources = ["source.proxmox-iso.rocky-9"]

  provisioner "ansible" {
    playbook_file     = "../../ansible/playbooks/rocky.yml"
    user              = var.ssh_username
    use_proxy         = false
    ansible_env_vars  = ["ANSIBLE_ROLES_PATH=../../ansible/roles"]
  }

  provisioner "shell" {
    inline = [
      "sudo cloud-init clean --logs",
      "sudo rm -f /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
    ]
  }
}
