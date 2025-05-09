output "proxmox_credentials" {
  value     = local.proxmox_credentials
  sensitive = true
}

output "ssh_public_key" {
  value     = local.ssh_public_key
  sensitive = true
}

output "ssh_private_key" {
  value     = local.ssh_private_key
  sensitive = true
}

output "proxmox_ssh_public_key" {
  value     = local.proxmox_ssh_public_key
  sensitive = true
}

output "proxmox_ssh_private_key" {
  value     = local.proxmox_ssh_private_key
  sensitive = true
}
