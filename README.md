# vm-templates

Builds golden VM templates on Proxmox VE with Packer + cloud-init/Autounattend +
Ansible, then deploys VMs from those templates with Terraform.

## Pipeline

1. **Packer** boots each OS's installer against Proxmox, drives an unattended
   install (cloud-init `autoinstall` for Ubuntu, a kickstart file for Rocky,
   `Autounattend.xml` for Windows), runs the **Ansible** playbook for that OS
   over SSH/WinRM to install the QEMU guest agent and baseline config, then
   converts the resulting VM into a Proxmox template. The Windows build
   produces two templates from one `packer build` — Server Core and Server
   with Desktop Experience — see
   [packer/windows-server-2025](packer/windows-server-2025).
2. **Terraform** clones a template into one or more VMs per environment,
   passing per-VM identity (hostname, IP, SSH keys) through Proxmox's
   built-in cloud-init support.

```
packer/       one directory per OS, produces a Proxmox template
ansible/      playbooks + roles run by Packer during the build
terraform/    reusable module to clone templates into VMs, per-environment stacks
cloud-init/   optional custom cloud-init snippets for advanced per-VM config
```

## Prerequisites

- Packer >= 1.10 with the `proxmox` plugin (`packer init` installs it from
  each build's `required_plugins` block)
- Terraform >= 1.7
- Ansible >= 2.15, plus `pywinrm` (`pip install pywinrm`) for the Windows
  playbook
- A Proxmox API token with permission to manage VMs/storage on the target
  node (`Datacenter -> Permissions -> API Tokens`)
- ISOs for each OS uploaded to Proxmox storage (or reachable via URL) — see
  each `packer/<os>/variables.pkr.hcl` for the expected variable

## Credentials

Nothing in this repo is meant to hold real secrets. Export Proxmox
credentials as environment variables before running Packer or Terraform:

```sh
export PROXMOX_URL="https://proxmox.example.lan:8006/api2/json"
export PROXMOX_API_TOKEN_ID="terraform@pve!vm-templates"
export PROXMOX_API_TOKEN_SECRET="..."
```

Packer reads these via `env("...")` in each build's variables file.
Terraform reads them via the `proxmox_api_token_id` / `proxmox_api_token_secret`
provider variables (see `terraform/environments/example/terraform.tfvars.example`).

## Building a template

```sh
cd packer/ubuntu-2404
cp example.auto.pkrvars.hcl.example example.auto.pkrvars.hcl   # edit values
packer init .
packer build .
```

Repeat per OS directory. Each build leaves a template on the configured
Proxmox node named after the `template_name` variable (e.g. `tpl-ubuntu-2404`).
`packer/windows-server-2025` builds two templates (`tpl-windows-server-2025-core`
and `tpl-windows-server-2025-desktop`) in a single `packer build .`.

## Deploying VMs from a template

```sh
cd terraform/environments/example
cp terraform.tfvars.example terraform.tfvars   # edit values
terraform init
terraform plan
terraform apply
```

## Adding a new OS

Copy the closest existing `packer/<os>` directory as a starting point, add a
matching Ansible playbook under `ansible/playbooks/`, and reference the new
template name from `terraform/modules/proxmox-vm` consumers.
