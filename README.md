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
- The Ansible collections in `ansible/requirements.yml`
  (`community.general`, `ansible.windows`, `community.windows`) — install
  with `ansible-galaxy collection install -r ansible/requirements.yml`.
  Without these, the playbooks fail with `couldn't resolve module/action`
  errors partway through a Packer build.
- A Proxmox API token with permission to manage VMs/storage on the target
  node (`Datacenter -> Permissions -> API Tokens`)
- ISOs for each OS uploaded to Proxmox storage (or reachable via URL) — see
  each `packer/<os>/variables.pkr.hcl` for the expected variable

## Running Packer from WSL2

Packer's `proxmox-iso` builder serves each build's kickstart/autoinstall file
(`http_directory`) from a local HTTP server, and the booting VM must be able
to reach it — the builds set `http_interface = "eth0"` so Packer advertises
that interface's address instead of auto-picking a local address, which can
end up choosing something unreachable (a loopback alias, VPN interface, etc).

By default WSL2 puts `eth0` behind NAT, so even its address isn't reachable
from a VM on your Proxmox network — the boot will hang trying to fetch the
kickstart/autoinstall file. Fix this once by switching WSL2 to mirrored
networking, which shares your Windows host's real network directly:

1. Create or edit `.wslconfig` in your Windows user profile
   (`%USERPROFILE%\.wslconfig`) with:
   ```ini
   [wsl2]
   networkingMode=mirrored
   ```
2. From PowerShell (not from inside WSL — this restarts the WSL VM):
   `wsl --shutdown`
3. Reopen your WSL terminal and confirm `ip addr show eth0` now shows your
   real LAN address rather than a `172.x`/NAT-range address.

Mirrored networking requires Windows 11 22H2 or later. If that's not
available, run `packer build` from a machine that's actually on the Proxmox
network instead of from WSL2.

Mirrored mode exposes WSL2's HTTP server on your real NIC, but Windows
Defender Firewall still applies its normal inbound rules to that traffic —
a VM on another VLAN/subnet will see the connection time out even though the
server is listening (`ss -tunlp` shows it bound) unless there's an explicit
allow rule. The builds pin the server to `http_port_min`/`http_port_max`
(8300-8310) so you only need to open this once. From an elevated (Admin)
PowerShell on Windows:

```powershell
$FirewallRuleParams = @{
  DisplayName   = "Packer HTTP (WSL2 mirrored)"
  Direction     = "Inbound"
  Protocol      = "TCP"
  LocalPort     = "8300-8310"
  RemoteAddress = "10.100.30.0/24"
  Action        = "Allow"
  Profile       = "Domain", "Private"
}
New-NetFirewallRule @FirewallRuleParams
```

Adjust `-RemoteAddress` if VM templates get built on other subnets/VLANs.

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

## SSH keys for Ansible provisioning

Each Linux build (`rocky-9`, `ubuntu-2404`) authenticates over SSH with a
dedicated, build-only keypair at `packer/<os>/files/ansible_build_key`
instead of a password. This works around a
[long-standing Packer bug](https://github.com/hashicorp/packer/issues/10639)
where the `ansible` provisioner's auto-generated temporary key comes out
blank/corrupt when the communicator uses password auth, causing
`Load key "...": invalid format` partway through a build.

These keypairs are gitignored (`packer/*/files/ansible_build_key*`) since a
fresh clone won't have them. Generate your own per OS before building:

```sh
cd packer/rocky-9   # or packer/ubuntu-2404
ssh-keygen -t ed25519 -N "" -f files/ansible_build_key
cat files/ansible_build_key.pub
```

Then paste the printed public key over the existing one in:
- **rocky-9**: the `sshkey --username=ansible "..."` line in `http/ks.cfg`
  (a separate kickstart command, not a `user` option — pykickstart rejects
  `--sshkey` on the `user` line with `unrecognized arguments`)
- **ubuntu-2404**: the `ssh_authorized_keys` entry in `http/user-data`

The key only grants access to a throwaway VM that gets destroyed (or has its
account provisioned away) before the template is finalized, so committing
the *public* half to a fork/branch isn't a real secret exposure — but the
private key stays local and gitignored regardless.

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
