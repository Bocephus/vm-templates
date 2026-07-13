provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  ssh {
    agent = true
  }
}

module "ubuntu_vm01" {
  source = "../../modules/proxmox-vm"

  name              = "ubuntu-vm01"
  target_node       = var.target_node
  template_vm_id    = 9000 # tpl-ubuntu-2404, see packer/ubuntu-2404
  os_type           = "linux"
  disk_datastore_id = var.disk_datastore_id
  ip_address        = "10.0.0.51/24"
  gateway           = "10.0.0.1"
  dns_servers       = ["10.0.0.1"]
  ssh_keys          = var.ssh_keys
  tags              = ["ubuntu", "terraform"]
}

module "rocky_vm01" {
  source = "../../modules/proxmox-vm"

  name              = "rocky-vm01"
  target_node       = var.target_node
  template_vm_id    = 9001 # tpl-rocky-9, see packer/rocky-9
  os_type           = "linux"
  disk_datastore_id = var.disk_datastore_id
  ip_address        = "10.0.0.52/24"
  gateway           = "10.0.0.1"
  dns_servers       = ["10.0.0.1"]
  ssh_keys          = var.ssh_keys
  tags              = ["rocky", "terraform"]
}

module "windows_vm01" {
  source = "../../modules/proxmox-vm"

  name              = "win-vm01"
  target_node       = var.target_node
  template_vm_id    = 9002 # tpl-windows-server-2025, see packer/windows-server-2025
  os_type           = "windows"
  cores             = 4
  memory            = 4096
  disk_datastore_id = var.disk_datastore_id
  disk_size         = 60
  tags              = ["windows", "terraform"]
}

output "ubuntu_vm01_ip" {
  value = module.ubuntu_vm01.ipv4_addresses
}

output "rocky_vm01_ip" {
  value = module.rocky_vm01.ipv4_addresses
}

output "windows_vm01_ip" {
  value = module.windows_vm01.ipv4_addresses
}
