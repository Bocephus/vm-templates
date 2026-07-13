# Generalizes the image (new SID/machine identity on every clone) and
# shuts the VM down. Packer waits for the VM to power off, then Proxmox
# converts it into a template.
& "$env:SystemRoot\System32\Sysprep\sysprep.exe" /generalize /oobe /shutdown /quiet
